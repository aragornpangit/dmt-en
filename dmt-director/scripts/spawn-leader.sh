#!/usr/bin/env bash
# For managers: open leader panes by threshold (the 1st to the right of the manager, the 2nd onward below the previous leader)
# Usage: bash spawn-leader.sh <devm|anam> <n> [--dry-run] [--no-start]
#   requires HERDR_ENV=1, HERDR_WORKSPACE_ID, HERDR_PANE_ID (the manager's own pane)
set -eu
ROLE="${1:?usage: spawn-leader.sh <devm|anam> <n> [--dry-run] [--no-start]}"
N="${2:?missing n}"
shift 2 || true
DRY=0; START=1
for a in "$@"; do
  case "$a" in --dry-run) DRY=1 ;; --no-start) START=0 ;; *) echo "unknown arg: $a" >&2; exit 2 ;; esac
done
case "$ROLE" in devm|anam) ;; *) echo "role must be devm|anam" >&2; exit 2 ;; esac
case "$N" in ''|*[!0-9]*) echo "n must be a positive integer" >&2; exit 2 ;; esac

h() { if [ "$DRY" = 1 ]; then echo "+ $*" >&2; else "$@"; fi; }
pane_by_label() {
  HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
    | jq -r --arg l "$1" '.result.panes[] | select(.label==$l) | .pane_id' | head -1
}

if [ "$ROLE" = devm ]; then
  PREFIX=devtl; ME=devm; SKILL='/dmt-dtl'
else
  PREFIX=anatl; ME=anam; SKILL='/dmt-atl'
fi
LABEL="${PREFIX}${N}"

if [ -n "$(pane_by_label "$LABEL" || true)" ]; then
  echo "$LABEL already exists"; exit 0
fi

me="$(pane_by_label "$ME" || true)"
[ -n "$me" ] || { echo "manager pane '$ME' not found" >&2; exit 3; }

if [ "$N" -eq 1 ]; then
  base="$me"; dir=right
else
  prev="${PREFIX}$((N-1))"
  base="$(pane_by_label "$prev" || true)"
  [ -n "$base" ] || { echo "previous leader pane '$prev' not found" >&2; exit 3; }
  dir=down
fi

pane="$(HERDR_ENV=1 herdr pane split "$base" --direction "$dir" --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')"
h env HERDR_ENV=1 herdr pane rename "$pane" "$LABEL"
if [ "$START" = 1 ]; then
  h env HERDR_ENV=1 herdr pane send-text "$pane" 'codebuddy --permission-mode auto'
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
  h env HERDR_ENV=1 herdr pane wait-output "$pane" --source visible --match 'auto mode on' --timeout 60000
  h env HERDR_ENV=1 herdr pane send-text "$pane" "$SKILL"
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
fi
echo "spawned $LABEL ($pane)"
