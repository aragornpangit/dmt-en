#!/usr/bin/env bash
# PreToolUse hook: while units are undispatched a manager must not write deliverables itself (the teeth of dispatch first)
# Usage: self-work-guard.sh <role> <file>
set -eu
ROLE="${1:?usage: self-work-guard.sh <role> <file>}"
FILE="${2:-}"
# hook payload arrives on stdin (JSON); prefer it, the CLI argument is only a fallback
payload=""; if [ ! -t 0 ]; then payload="$(timeout 1 cat 2>/dev/null || true)"; fi
if [ -z "$FILE" ] && [ -n "$payload" ]; then
  FILE="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path // empty' 2>/dev/null || true)"
fi
[ -n "$FILE" ] || exit 0
# Normalize to an absolute path: the hook sometimes passes a relative path, and the relative form would bypass the */docs/... patterns below
FILE="$(realpath -m "$FILE" 2>/dev/null || printf '%s' "$FILE")"
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib-dmt.sh"
# Role resolution: argument "-" or empty => $DMT_ROLE => herdr pane label; only director/devm/anam and helpers (director-helper/devm-helper/anam-helper) are governed
ROLE="$(dmt_role "$ROLE")"
if [ "${DMT_DISPATCH_ALL:-0}" != 1 ]; then
  case "$ROLE" in director|devm|anam|director-helper|devm-helper|anam-helper) ;; *) exit 0 ;; esac
fi
case "$FILE" in
  */docs/pd/*|*/docs/dev/tickets/*|*/docs/analyst/*|*/docs/human/*) ;;
  *) exit 0 ;;
esac
# The signal is only "units still undispatched": >= 1 in flight must still be blocked (otherwise dispatching one unit lets you write all the remaining deliverables yourself)
LEDGER="$(bash "$DIR/dispatch-ledger.sh" ledger-path "$ROLE" 2>/dev/null || true)"
if [ -n "$LEDGER" ] && [ -f "$LEDGER" ]; then
  pending="$(awk -F'\t' '$2=="planned"{c++} END{print c+0}' "$LEDGER")"
  [ "$pending" -ge 1 ] || exit 0
else
  exit 0
fi
{
  echo "[self-work-guard] this file is a deliverable, i.e. unit work, and this batch still has undispatched units."
  echo "[self-work-guard] dispatch sub-agents first (team.md §5.2 dispatch first), or record a reason with dispatch-ledger.sh excuse <role> <unit> <code>."
  bash "$DIR/dispatch-ledger.sh" report "$ROLE" || true
} >&2
exit 2
