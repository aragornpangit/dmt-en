#!/usr/bin/env bash
# For director: rename yourself, create the pm / devm / anam panes and start cbc in them
# (creating and starting are both idempotent)
# Usage: bash setup-team.sh [--dry-run] [--no-start] [--force-start] [--reload]
#   --no-start     only create panes, do not start
#   --force-start  resend the start command even if an agent is already running
#                  (default: skip -- sending a start command to a running agent is read as a user prompt)
#   --reload       for a pane that is already running only resend the skill command
#                  (reload the skill, no start command)
#   requires env vars HERDR_ENV=1, HERDR_PANE_ID, HERDR_TAB_ID, HERDR_WORKSPACE_ID
set -eu
DRY=0; START=1; FORCE=0; RELOAD=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --no-start) START=0 ;;
    --force-start) FORCE=1 ;;
    --reload) RELOAD=1 ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done
: "${HERDR_ENV:?must run inside herdr (HERDR_ENV=1)}"
: "${HERDR_PANE_ID:?missing HERDR_PANE_ID}"
: "${HERDR_TAB_ID:?missing HERDR_TAB_ID}"
: "${HERDR_WORKSPACE_ID:?missing HERDR_WORKSPACE_ID}"

h() { if [ "$DRY" = 1 ]; then echo "+ $*" >&2; else "$@"; fi; }
pane_by_label() {
  HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
    | jq -r --arg l "$1" '.result.panes[] | select(.label==$l) | .pane_id' | head -1
}
# agent_status: unknown = no agent running in this pane; idle/working/blocked = already running
pane_status() {
  HERDR_ENV=1 herdr pane get "$1" 2>/dev/null \
    | jq -r '.result.pane.agent_status // "unknown"' 2>/dev/null || echo unknown
}
# Readiness signal: poll agent_status until it is no longer unknown.
# Do not use wait-output matching on screen text -- for a pane that is already running it
# matches historical output immediately, so it is not a readiness gate at all.
wait_ready() {
  local pane="$1" i=0 st
  while [ "$i" -lt 60 ]; do
    st="$(pane_status "$pane")"
    if [ "$st" != "unknown" ]; then echo "ready ($st): $pane"; return 0; fi
    sleep 1; i=$((i + 1))
  done
  echo "WARN: $pane still unknown after 60s; skill command sent anyway" >&2
  return 1
}
ensure_started() {
  local pane="$1" skill="$2" st
  [ "$START" = 1 ] || { echo "skip start: $pane"; return 0; }
  if [ "$DRY" = 1 ]; then
    echo "+ [dry] start $pane: codebuddy --permission-mode auto  then  $skill" >&2
    return 0
  fi
  st="$(pane_status "$pane")"
  if [ "$st" != "unknown" ] && [ "$FORCE" != 1 ]; then
    echo "already running (agent_status=$st): $pane -- start command not resent"
    if [ "$RELOAD" = 1 ]; then
      h env HERDR_ENV=1 herdr pane send-text "$pane" "$skill"
      h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
      echo "reloaded skill on $pane"
    fi
    return 0
  fi
  h env HERDR_ENV=1 herdr pane send-text "$pane" 'codebuddy --permission-mode auto'
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
  wait_ready "$pane" || true
  h env HERDR_ENV=1 herdr pane send-text "$pane" "$skill"
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
}

# 1) Rename yourself: tab first, then pane
h env HERDR_ENV=1 herdr tab rename "$HERDR_TAB_ID" director
h env HERDR_ENV=1 herdr pane rename "$HERDR_PANE_ID" director

# 2) pm: split to the right of the director pane
pm="$(pane_by_label pm || true)"
if [ -z "$pm" ]; then
  pm="$(HERDR_ENV=1 herdr pane split "$HERDR_PANE_ID" --direction right --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')"
  h env HERDR_ENV=1 herdr pane rename "$pm" pm
fi
ensure_started "$pm" '/dmt-pm'

# 3) devm / anam: each gets its own tab
for role in devm anam; do
  p="$(pane_by_label "$role" || true)"
  if [ -z "$p" ]; then
    p="$(HERDR_ENV=1 herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label "$role" | jq -r '.result.root_pane.pane_id')"
    h env HERDR_ENV=1 herdr pane rename "$p" "$role"
  fi
  case "$role" in devm) skill='/dmt-dm' ;; anam) skill='/dmt-am' ;; esac
  ensure_started "$p" "$skill"
done
echo "team ready: director / pm / devm / anam"
