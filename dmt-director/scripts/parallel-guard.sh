#!/usr/bin/env bash
# PreToolUse hook: while governed roles still have undispatched units, synchronous (non-background) Agent
# calls are blocked -- dispatching must run in parallel
# Usage: parallel-guard.sh <role|->
# the hook payload (stdin JSON) carries .tool_name and .tool_input.run_in_background
set -eu
ROLE="${1:--}"
payload=""; if [ ! -t 0 ]; then payload="$(timeout 1 cat 2>/dev/null || true)"; fi
[ -n "$payload" ] || exit 0
tn="$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null || true)"
case "$tn" in Agent|Task|Teammate|teammate) ;; *) exit 0 ;; esac
rb="$(printf '%s' "$payload" | jq -r '.tool_input.run_in_background // false' 2>/dev/null || true)"
[ "$rb" = "true" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib-dmt.sh"
ROLE="$(dmt_role "$ROLE")"
if [ "${DMT_DISPATCH_ALL:-0}" != 1 ]; then
  case "$ROLE" in director|devm|anam|director-helper|devm-helper|anam-helper) ;; *) exit 0 ;; esac
fi
LEDGER="$(bash "$DIR/dispatch-ledger.sh" ledger-path "$ROLE" 2>/dev/null || true)"
[ -n "$LEDGER" ] && [ -f "$LEDGER" ] || exit 0
pending="$(awk -F'\t' '$2=="planned"{c++} END{print c+0}' "$LEDGER")"
[ "$pending" -ge 1 ] || exit 0
{
  echo "[parallel-guard] this batch still has $pending undispatched units: Agent calls must use run_in_background: true,"
  echo "[parallel-guard] and be dispatched concurrently within the same reply (open on demand, capped at min(8, cap)); synchronous calls turn parallel work serial."
  bash "$DIR/dispatch-ledger.sh" report "$ROLE" || true
} >&2
exit 2
