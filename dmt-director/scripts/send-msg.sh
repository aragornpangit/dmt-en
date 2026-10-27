#!/usr/bin/env bash
# Send an inbox message + herdr doorbell (filename and direction generated automatically)
# Usage: bash send-msg.sh <to> <from> <slug> <body-file> [--dry-run]
#   from in director|devm|anam|{role}-helper; to in director|devm|anam (a helper has no inbox of its own and accepts no further input)
#   A one-way report from a helper is written to the box only, without a doorbell (the primary collects it by scanning the box)
# Serial: max(highest number found by scanning inbox/<to>/** including .doing/, inbox/<to>/.seq high-water) + 1
set -eu
TO="${1:?usage: send-msg.sh <to> <from> <slug> <body-file>}"
FROM="${2:?missing from}"
SLUG="${3:?missing slug}"
BODY="${4:?missing body file}"
DRY=0; [ "${5:-}" = "--dry-run" ] && DRY=1
# Sender allowlist: director|devm|anam|{role}-helper (helpers report results one-way to the primary); the recipients do not include helpers
# A helper is a pure clone of the role (user ruling): has no inbox of its own and accepts no further input -- its task is a one-shot dispatch via spawn-helper
for who in "$TO"; do
  case "$who" in
    director|devm|anam) ;;
    director-helper|devm-helper|anam-helper)
      echo "a helper accepts no further input and has no inbox of its own (its task is a one-shot dispatch via spawn-helper, and its results are reported one-way back to the primary): $TO cannot be a recipient" >&2; exit 2 ;;
    *) echo "bad role: $TO (want director|devm|anam)" >&2; exit 2 ;;
  esac
done
case "$FROM" in
  director|devm|anam|director-helper|devm-helper|anam-helper) ;;
  *) echo "bad role: $FROM (want director|devm|anam|{role}-helper)" >&2; exit 2 ;;
esac
[ -f "$BODY" ] || { echo "body file not found: $BODY" >&2; exit 2; }
[ -s "$BODY" ] || { echo "body file is empty: $BODY" >&2; exit 2; }

# Locate the inbox at the main worktree root (same rule as dispatch-ledger; running inside a worktree still points back at the main tree)
DIR="$(cd "$(dirname "$0")" && pwd)"; . "$DIR/lib-dmt.sh"
ROOT="$(dmt_root)"
# Concurrency-ledger gate: reporting to your superior requires settling the ledger -- refuse to send while units are undispatched and a concurrency slot is free (DMT_MSG_FORCE=1 forces it)
DIR="$(cd "$(dirname "$0")" && pwd)"
superior_of() {
  case "$1" in
    devm|anam) echo director ;;
    *) echo "" ;;
  esac
}
SUP="$(superior_of "$FROM")"
if [ -n "$SUP" ] && [ "$SUP" = "$TO" ] && [ "${DMT_MSG_FORCE:-0}" != 1 ]; then
  if ! bash "$DIR/dispatch-ledger.sh" check "$FROM" >/dev/null 2>&1; then
    echo "[send-msg] concurrency-ledger gate: units are still undispatched and a concurrency slot is free; open on demand, capped at min(8, cap); dispatch first, then report (DMT_MSG_FORCE=1 forces the send)." >&2
    bash "$DIR/dispatch-ledger.sh" report "$FROM" >&2 || true
    exit 2
  fi
fi
BOX="$ROOT/inbox/$TO"
mkdir -p "$BOX/.doing"

# Serialize "pick a number + write the file + update .seq": one inbox has several writers (devm / anam / three helpers)
LOCK="$BOX/.seq.lock"
tries=0
while ! mkdir "$LOCK" 2>/dev/null; do
  tries=$((tries + 1))
  [ "$tries" -lt 300 ] || { echo "[send-msg] timed out waiting for lock: $LOCK" >&2; exit 4; }
  sleep 0.1
done
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

# Self-healing scan: highest number currently in the root and .doing/ (fallback when .seq is lost or copied)
scan_max="$(find "$BOX" -maxdepth 2 -name '[0-9]*-*' -printf '%f\n' 2>/dev/null \
            | sed -n 's/^0*\([0-9]\{1,\}\)-.*/\1/p' | sort -n | tail -1 || true)"
# High-water: the highest number ever issued; does not regress when messages are deleted (must be a decimal integer without leading zeros)
file_max="$(cat "$BOX/.seq" 2>/dev/null || echo 0)"
case "$file_max" in ''|*[!0-9]*) file_max=0 ;; esac
# Important: filenames carry leading zeros (077), and an older .seq may also have been written with
# zeros; bash arithmetic treats 077 as octal (= 63), pushing the counter back to 64 and creating
# duplicate numbers. Force base 10 for every comparison and increment.
[ -n "${scan_max:-}" ] || scan_max=0
scan_max=$((10#$scan_max))
file_max=$((10#$file_max))
if [ "$scan_max" -gt "$file_max" ]; then file_max="$scan_max"; fi
seq_num=$(( file_max + 1 ))
seq="$(printf '%03d' "$seq_num")"
ts="$(date +%y%m%d%H%M)"
DIRECTION="${FROM}2${TO}"
NAME="${seq}-${DIRECTION}-${SLUG}-${ts}.md"

if [ "$DRY" = 1 ]; then
  echo "+ cp $BODY $BOX/$NAME"; echo "+ printf '%d\n' $seq_num > $BOX/.seq"; echo "+ doorbell -> $TO"; exit 0
fi
cp "$BODY" "$BOX/$NAME"
printf '%d\n' "$seq_num" > "$BOX/.seq.tmp" && mv "$BOX/.seq.tmp" "$BOX/.seq"
rmdir "$LOCK" 2>/dev/null || true; trap - EXIT

# A helper's one-way report only writes to the box, with no doorbell (no doorbell round trip): the primary collects it by scanning the box
case "$FROM" in
  *-helper) echo "$NAME"; exit 0 ;;
esac

pane="$(HERDR_ENV=1 herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" \
  | jq -r --arg l "$TO" '.result.panes[] | select(.label==$l) | .pane_id' | head -1 || true)"
[ -n "$pane" ] || { echo "WARN: pane label '$TO' not found; message written, doorbell skipped" >&2; echo "$NAME"; exit 0; }

MSG="you have a new message ${NAME} in inbox/${TO}/"
out="$(HERDR_ENV=1 herdr agent prompt "$pane" "$MSG" 2>&1 || true)"
case "$out" in
  *agent_prompted*) ;;
  *)
    HERDR_ENV=1 herdr pane send-text "$pane" "$MSG"
    HERDR_ENV=1 herdr pane send-keys "$pane" enter
    ;;
esac
echo "$NAME"
