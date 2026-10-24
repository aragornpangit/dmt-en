#!/usr/bin/env bash
# PreToolUse hook: while units are undispatched a manager must not write deliverables itself (the teeth of dispatch-first)
# Usage: self-work-guard.sh <role> <file>
set -eu
ROLE="${1:?usage: self-work-guard.sh <role> <file>}"
FILE="${2:?missing file}"
DIR="$(cd "$(dirname "$0")" && pwd)"
case "$FILE" in
  */docs/pd/*|*/docs/dev/tickets/*|*/docs/analyst/*|*/docs/human/*) ;;
  *) exit 0 ;;
esac
if bash "$DIR/dispatch-ledger.sh" check "$ROLE" >/dev/null 2>&1; then exit 0; fi
{
  echo "[self-work-guard] this file is a deliverable, i.e. unit work, and this batch still has undispatched units."
  echo "[self-work-guard] dispatch sub-agents first (team.md §5.2 dispatch first), or record a reason with dispatch-ledger.sh excuse <unit> <code>."
  bash "$DIR/dispatch-ledger.sh" report "$ROLE" || true
} >&2
exit 2
