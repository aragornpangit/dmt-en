#!/usr/bin/env bash
# Send an inbox message + herdr doorbell (file name and direction are generated automatically)
# Usage: bash send-msg.sh <to> <from> <slug> <body-file> [--dry-run]
#   to/from ∈ director|pm|devm|anam|devtl{n}|anatl{n}
set -eu
TO="${1:?usage: send-msg.sh <to> <from> <slug> <body-file>}"
FROM="${2:?missing from}"
SLUG="${3:?missing slug}"
BODY="${4:?missing body file}"
DRY=0; [ "${5:-}" = "--dry-run" ] && DRY=1
[ -f "$BODY" ] || { echo "body file not found: $BODY" >&2; exit 2; }
[ -s "$BODY" ] || { echo "body file is empty: $BODY" >&2; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BOX="$ROOT/inbox/$TO"
mkdir -p "$BOX"
last="$(ls "$BOX" 2>/dev/null | sed -n 's/^\([0-9][0-9][0-9]\)-.*/\1/p' | sort -n | tail -1)"
seq=$(printf '%03d' $(( ${last:-0} + 1 )))
ts="$(date +%y%m%d%H%M)"
DIRECTION="${FROM}2${TO}"
NAME="${seq}-${DIRECTION}-${SLUG}-${ts}.md"

if [ "$DRY" = 1 ]; then
  echo "+ cp $BODY $BOX/$NAME"; echo "+ doorbell -> $TO"; exit 0
fi
cp "$BODY" "$BOX/$NAME"

pane="$(HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
  | jq -r --arg l "$TO" '.result.panes[] | select(.label==$l) | .pane_id' | head -1)"
[ -n "$pane" ] || { echo "WARN: pane label '$TO' not found; message written, doorbell skipped" >&2; echo "$NAME"; exit 0; }

MSG="You have a new message ${NAME}, in inbox/${TO}/"
out="$(HERDR_ENV=1 herdr agent prompt "$pane" "$MSG" 2>&1 || true)"
case "$out" in
  *agent_prompted*) ;;
  *)
    HERDR_ENV=1 herdr pane send-text "$pane" "$MSG"
    HERDR_ENV=1 herdr pane send-keys "$pane" enter
    ;;
esac
echo "$NAME"
