#!/usr/bin/env bash
# Send an inbox message + herdr doorbell (filename and direction generated automatically)
# Usage: bash send-msg.sh <to> <from> <slug> <body-file> [--dry-run]
#   to/from in director|pm|devm|anam|devtl{n}|anatl{n}
# Serial: max(highest number found by scanning inbox/<to>/** including .doing/, inbox/<to>/.seq high-water) + 1
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
mkdir -p "$BOX/.doing"

# Self-healing scan: highest number currently in the root and .doing/ (fallback when .seq is lost or copied)
scan_max="$(find "$BOX" -maxdepth 2 -name '[0-9]*-*' -printf '%f\n' 2>/dev/null \
            | sed -n 's/^\([0-9]\{1,\}\)-.*/\1/p' | sort -n | tail -1 || true)"
# High-water: the highest number ever issued; does not regress when messages are deleted (must be a decimal integer without leading zeros)
file_max="$(cat "$BOX/.seq" 2>/dev/null || echo 0)"
case "$file_max" in ''|*[!0-9]*) file_max=0 ;; esac
[ -n "${scan_max:-}" ] || scan_max=0
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

pane="$(HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
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
