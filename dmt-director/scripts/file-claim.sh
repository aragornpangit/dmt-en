#!/usr/bin/env bash
# dmt file claim registry (check before editing to avoid concurrent writes to the same file)
# Model borrowed from Orca: first check whether an active agent is in the same worktree, then register the claim on this file.
# Usage:
#   bash file-claim.sh check   <path> [owner]
#   bash file-claim.sh claim   <path> <owner>
#   bash file-claim.sh release <path> <owner>
#   bash file-claim.sh list
# Return codes: 0 writable/success; 3 held by someone else; 2 usage error
# Env vars: DMT_LOCKS_DIR (default <project-root>/locks), DMT_CLAIM_TTL (seconds, default 1800)
set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOCKS="${DMT_LOCKS_DIR:-$ROOT/locks}"
TTL="${DMT_CLAIM_TTL:-1800}"
mkdir -p "$LOCKS" 2>/dev/null

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

cmd="${1:-}"; target="${2:-}"; owner="${3:-}"
if [ "$cmd" != "list" ]; then
  [ -n "$cmd" ] && [ -n "$target" ] || usage
fi

# Normalize to a path relative to the project root (non-existent files are fine; list needs no target)
rel=""; lock=""
if [ -n "$target" ]; then
  abs="$(realpath -m "$target")"
  rel="${abs#"$ROOT"/}"
  [ "$rel" = "$abs" ] && rel="$(basename "$abs")"
  key="$(printf '%s' "$rel" | sha1sum | cut -c1-16)"
  lock="$LOCKS/$key.lock"
fi

now() { date +%s; }
read_ts() { [ -f "$1/ts" ] && cat "$1/ts" || echo 0; }
read_owner() { [ -f "$1/owner" ] && cat "$1/owner" || echo "?"; }
expired() { [ $(( $(now) - $(read_ts "$1") )) -gt "$TTL" ]; }

case "$cmd" in
  check)
    if [ ! -d "$lock" ]; then
      echo "FREE  $rel"
      exit 0
    fi
    o="$(read_owner "$lock")"
    if expired "$lock"; then
      echo "STALE $rel (previous owner $o, over ${TTL}s) — may be preempted; state the preemption in your report"
      exit 0
    fi
    if [ -n "$owner" ] && [ "$o" = "$owner" ]; then
      echo "MINE  $rel ($o)"
      exit 0
    fi
    echo "BUSY  $rel held by $o ($(( $(now) - $(read_ts "$lock") ))s)"
    exit 3
    ;;

  claim)
    [ -n "$owner" ] || usage
    if mkdir "$lock" 2>/dev/null; then
      printf '%s' "$rel"   > "$lock/path"
      printf '%s' "$owner" > "$lock/owner"
      now                  > "$lock/ts"
      echo "CLAIMED $rel by $owner"
      exit 0
    fi
    o="$(read_owner "$lock")"
    if [ "$o" = "$owner" ]; then
      now > "$lock/ts"
      echo "RENEWED $rel by $owner"
      exit 0
    fi
    if expired "$lock"; then
      rm -rf "$lock"
      if mkdir "$lock" 2>/dev/null; then
        printf '%s' "$rel"   > "$lock/path"
        printf '%s' "$owner" > "$lock/owner"
        now                  > "$lock/ts"
        echo "CLAIMED $rel by $owner (took over expired lock, previous owner $o)"
        exit 0
      fi
    fi
    echo "BUSY  $rel held by $o ($(( $(now) - $(read_ts "$lock") ))s)"
    exit 3
    ;;

  release)
    [ -n "$owner" ] || usage
    if [ ! -d "$lock" ]; then
      echo "FREE  $rel (no claim)"
      exit 0
    fi
    o="$(read_owner "$lock")"
    if [ "$o" != "$owner" ]; then
      echo "BUSY  $rel held by $o; $owner may not release it"
      exit 3
    fi
    rm -rf "$lock"
    echo "RELEASED $rel by $owner"
    exit 0
    ;;

  list)
    found=0
    for d in "$LOCKS"/*.lock; do
      [ -d "$d" ] || continue
      found=1
      p="$(cat "$d/path" 2>/dev/null || echo '?')"
      o="$(read_owner "$d")"
      age=$(( $(now) - $(read_ts "$d") ))
      st="active"; expired "$d" && st="stale"
      echo "$st  $p  owner=$o  age=${age}s"
    done
    [ "$found" -eq 1 ] || echo "(no claims)"
    exit 0
    ;;

  *) usage ;;
esac
