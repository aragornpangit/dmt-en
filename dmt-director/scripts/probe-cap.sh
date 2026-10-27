#!/usr/bin/env bash
# Probe the maximum number of agents the current harness supports (cap) and print the team's effective concurrency limit CAP = min(8, cap).
# Priority: DMT_SUBAGENT_CAP > CODEBUDDY_CODE_MAX_CONCURRENT_SUBAGENTS > known harness default > 8
#   codebuddy's raw value is 20 (official sub-agents docs); any harness we cannot probe counts as 8.
#   Team concurrency cap is 8 (user ruling 2026-10-26): a cap > 8 counts as 8, and director/managers always use min(8, cap).
set -u
cap="${DMT_SUBAGENT_CAP:-}"
if [ -z "$cap" ]; then cap="${CODEBUDDY_CODE_MAX_CONCURRENT_SUBAGENTS:-}"; fi
[ -n "$cap" ] || cap=8
case "$cap" in ''|*[!0-9]*) cap=8 ;; esac
cap=$((10#$cap))
[ "$cap" -ge 1 ] || cap=8
if [ "$cap" -gt 8 ]; then cap=8; fi
echo "$cap"
