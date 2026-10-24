#!/usr/bin/env bash
# Manager only: close this batch's leader pane (pane only, never the tab; non-creators must not close for others)
# Usage: bash close-leader.sh <devm|anam> <n> [--force] [--dry-run]
set -eu
ROLE="${1:?usage: close-leader.sh <devm|anam> <n> [--force] [--dry-run]}"
N="${2:?missing n}"
shift 2 || true
FORCE=0; DRY=0
for a in "$@"; do
  case "$a" in --force) FORCE=1 ;; --dry-run) DRY=1 ;; *) echo "unknown arg: $a" >&2; exit 2 ;; esac
done
case "$ROLE" in devm|anam) ;; *) echo "role must be devm|anam" >&2; exit 2 ;; esac
if [ "$ROLE" = devm ]; then PREFIX=devtl; ME=devm; else PREFIX=anatl; ME=anam; fi
LABEL="${PREFIX}${N}"

pane="$(HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
  | jq -r --arg l "$LABEL" '.result.panes[] | select(.label==$l) | .pane_id' | head -1 || true)"
[ -n "$pane" ] || { echo "$LABEL not found (already closed?)"; exit 0; }

inbox="inbox/$ME"
unread="$(find "$inbox" -maxdepth 1 -name '*.md' 2>/dev/null | head -1 || true)"
doing="$(find "$inbox/.doing" -maxdepth 1 -name '*.md' 2>/dev/null | head -1 || true)"
if [ "$FORCE" != 1 ] && { [ -n "$unread" ] || [ -n "$doing" ]; }; then
  echo "REFUSE: $inbox still has unread or unclosed messages (root / .doing/); handle them first or add --force" >&2
  exit 3
fi

if [ "$DRY" = 1 ]; then echo "+ herdr pane close $pane"; else
  HERDR_ENV=1 herdr pane close "$pane"
  echo "closed $LABEL ($pane)"
fi
