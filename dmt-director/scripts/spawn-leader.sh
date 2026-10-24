#!/usr/bin/env bash
# For managers: open leader panes by threshold (the 1st to the right of the manager,
# the 2nd onward below the previous leader)
# Usage: bash spawn-leader.sh <devm|anam> <n> [--dry-run] [--no-start] [--force-start]
#   requires HERDR_ENV=1, HERDR_WORKSPACE_ID, HERDR_PANE_ID (the manager's own pane)
#   idempotent: an existing label is not re-created; if that pane has no agent running
#   (agent_status=unknown) the start command is sent
set -eu
ROLE="${1:?usage: spawn-leader.sh <devm|anam> <n> [--dry-run] [--no-start] [--force-start]}"
N="${2:?missing n}"
shift 2 || true
DRY=0; START=1; FORCE=0
for a in "$@"; do
  case "$a" in --dry-run) DRY=1 ;; --no-start) START=0 ;; --force-start) FORCE=1 ;; *) echo "unknown arg: $a" >&2; exit 2 ;; esac
done
case "$ROLE" in devm|anam) ;; *) echo "role must be devm|anam" >&2; exit 2 ;; esac
case "$N" in ''|*[!0-9]*) echo "n must be a positive integer" >&2; exit 2 ;; esac

h() { if [ "$DRY" = 1 ]; then echo "+ $*" >&2; else "$@"; fi; }
pane_by_label() {
  HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
    | jq -r --arg l "$1" '.result.panes[] | select(.label==$l) | .pane_id' | head -1
}
pane_status() {
  HERDR_ENV=1 herdr pane get "$1" 2>/dev/null \
    | jq -r '.result.pane.agent_status // "unknown"' 2>/dev/null || echo unknown
}
# Readiness signal: poll agent_status until it is no longer unknown (see setup-team.sh:
# wait-output on screen text is not a readiness gate for a pane that is already running).
wait_ready() {
  local pane="$1" i=0 st
  while [ "$i" -lt 60 ]; do
    st="$(pane_status "$pane")"
    if [ "$st" != "unknown" ]; then echo "ready ($st): $pane"; return 0; fi
    sleep 1; i=$((i + 1))
  done
  echo "WARN: $pane still unknown after 60s" >&2
  return 1
}
start_pane() {
  local pane="$1"
  [ "$START" = 1 ] || { echo "skip start: $pane"; return 0; }
  if [ "$DRY" = 1 ]; then echo "+ [dry] start $pane" >&2; return 0; fi
  local st; st="$(pane_status "$pane")"
  if [ "$st" != "unknown" ] && [ "$FORCE" != 1 ]; then
    echo "already running (agent_status=$st): $pane -- start command not resent"
    return 0
  fi
  h env HERDR_ENV=1 herdr pane send-text "$pane" 'codebuddy --permission-mode auto'
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
  wait_ready "$pane" || true
  h env HERDR_ENV=1 herdr pane send-text "$pane" "$SKILL"
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
}

if [ "$ROLE" = devm ]; then
  PREFIX=devtl; ME=devm; SKILL='/dmt-dtl'
else
  PREFIX=anatl; ME=anam; SKILL='/dmt-atl'
fi
LABEL="$PREFIX$N"

existing="$(pane_by_label "$LABEL" || true)"
if [ -n "$existing" ]; then
  echo "$LABEL already exists ($existing)"
  start_pane "$existing"
  exit 0
fi

me="$(pane_by_label "$ME" || true)"
[ -n "$me" ] || { echo "manager pane '$ME' not found" >&2; exit 3; }

if [ "$N" -eq 1 ]; then
  base="$me"; dir=right
else
  prev="$PREFIX$((N-1))"
  base="$(pane_by_label "$prev" || true)"
  [ -n "$base" ] || { echo "previous leader pane '$prev' not found" >&2; exit 3; }
  dir=down
fi

pane="$(HERDR_ENV=1 herdr pane split "$base" --direction "$dir" --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')"
h env HERDR_ENV=1 herdr pane rename "$pane" "$LABEL"
start_pane "$pane"
echo "spawned $LABEL ($pane)"
