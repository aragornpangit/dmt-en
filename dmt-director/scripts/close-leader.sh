#!/usr/bin/env bash
# For managers: close this batch's leader panes (close pane only, not tab; non-creators must not close on their behalf)
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
  | jq -r --arg l "$LABEL" '.result.panes[] | select(.label==$l) | .pane_id' | head -1)"
[ -n "$pane" ] || { echo "$LABEL not found (already closed?)"; exit 0; }

inbox="inbox/$ME"
if [ -d "$inbox" ] && [ -n "$(ls -A "$inbox" 2>/dev/null || true)" ] && [ "$FORCE" != 1 ]; then
  echo "REFUSE: $inbox still has unread messages; handle them first, or add --force" >&2
  exit 3
fi

if [ "$DRY" = 1 ]; then echo "+ herdr pane close $pane"; else
  HERDR_ENV=1 herdr pane close "$pane"
  echo "closed $LABEL ($pane)"
fi
