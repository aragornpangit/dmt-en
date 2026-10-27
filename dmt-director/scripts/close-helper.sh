#!/usr/bin/env bash
# For a primary role instance: reclaim the helper pane once the task is done (only panes may be closed, never the tab;
# the helper tab is kept for reuse; no one but the creator may close it)
# Usage: bash close-helper.sh <director|devm|anam> [--force] [--dry-run]
#   Inbox guard: only messages with direction ^[0-9]+-{role}-helper2{role}- (including .doing/) count as this helper's unread/unclosed
set -eu
ROLE="${1:?usage: close-helper.sh <director|devm|anam> [--force] [--dry-run]}"
shift || true
FORCE=0; DRY=0
for a in "$@"; do
  case "$a" in --force) FORCE=1 ;; --dry-run) DRY=1 ;; *) echo "unknown arg: $a" >&2; exit 2 ;; esac
done
case "$ROLE" in director|devm|anam) ;; *) echo "role must be director|devm|anam" >&2; exit 2 ;; esac
LABEL="${ROLE}-helper"

if ! list="$(HERDR_ENV=1 herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" 2>/dev/null)"; then
  echo "ERROR: herdr pane list failed; cannot confirm $LABEL state (do not treat it as closed)" >&2
  exit 4
fi
pane="$(printf '%s' "$list" | jq -r --arg l "$LABEL" '.result.panes[]? | select(.label==$l) | .pane_id' 2>/dev/null | head -1 || true)"
if [ -z "$pane" ]; then
  if [ "$DRY" = 1 ] && [ -z "$list" ]; then
    echo "(dry) herdr unavailable (pane list is empty); continuing with a placeholder pane" >&2
    pane="<${LABEL}-pane>"
  else
    echo "$LABEL not found (already closed?)"
    exit 0
  fi
fi

# Locate the inbox at the main worktree root (same rule as send-msg / msg-take; running inside a worktree still points back at the main tree)
DIR="$(cd "$(dirname "$0")" && pwd)"; . "$DIR/lib-dmt.sh"
root="$(dmt_root)"
inbox="$root/inbox/$ROLE"
# Filter unread by direction: only messages with ^[0-9]+-{role}-helper2{role}- (including .doing/) count as this helper's unread/unclosed
pat="^[0-9]+-${LABEL}2${ROLE}-"
unread="$(find "$inbox" -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null | grep -E "$pat" | head -1 || true)"
doing="$(find "$inbox/.doing" -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null | grep -E "$pat" | head -1 || true)"
if [ "$FORCE" != 1 ] && { [ -n "$unread" ] || [ -n "$doing" ]; }; then
  echo "REFUSE: $inbox still has unread or unclosed messages in the ${LABEL}2${ROLE} direction (unread ${unread:-none} / unclosed ${doing:-none}); never close before collecting -- handle them first, or add --force" >&2
  exit 3
fi

echo "Manual checklist (confirm each item before closing $LABEL): (1) the report has been booked (2) the worktree has been removed with git worktree remove (confirmed by the closer) (3) unread is checked automatically (this script checked the ${LABEL}2${ROLE} direction)"
if [ "$DRY" = 1 ]; then echo "+ herdr pane close $pane"; else
  HERDR_ENV=1 herdr pane close "$pane"
  echo "closed $LABEL ($pane) (helper tab kept for reuse)"
fi
