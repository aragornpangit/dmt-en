#!/usr/bin/env bash
# For director: rename yourself, create the devm (right of this tab) / anam (own tab) panes and start cbc in them
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
missing=""
[ -n "${HERDR_ENV:-}" ] || missing="$missing HERDR_ENV"
[ -n "${HERDR_PANE_ID:-}" ] || missing="$missing HERDR_PANE_ID"
[ -n "${HERDR_TAB_ID:-}" ] || missing="$missing HERDR_TAB_ID"
[ -n "${HERDR_WORKSPACE_ID:-}" ] || missing="$missing HERDR_WORKSPACE_ID"
[ -z "$missing" ] || { echo "missing environment variables:$missing (run this script inside the director pane)" >&2; exit 2; }

. "$(cd "$(dirname "$0")" && pwd)/lib-dmt.sh"

h() { if [ "$DRY" = 1 ]; then echo "+ $*" >&2; else "$@"; fi; }
pane_by_label() { dmt_pane_by_label "$1"; }
# agent_status: unknown = no agent running in this pane; idle/working/blocked = already running
pane_status() { dmt_pane_status "$1"; }
# Readiness signal: poll agent_status until it is no longer unknown.
# Do not use wait-output matching on screen text -- for a pane that is already running it
# matches historical output immediately, so it is not a readiness gate at all.
wait_ready() { dmt_wait_ready "$1" 60 || true; }
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

# 2) devm: split to the right of the director pane (same tab as director, director on the left, devm on the right)
devm="$(pane_by_label devm || true)"
if [ -z "$devm" ]; then
  if [ "$DRY" = 1 ]; then
    echo "+ herdr pane split $HERDR_PANE_ID --direction right --cwd $PWD --no-focus" >&2
    echo "+ herdr pane rename <devm-pane> devm" >&2
    devm="<devm-pane>"
  else
    devm="$(HERDR_ENV=1 herdr pane split "$HERDR_PANE_ID" --direction right --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id // empty')"
    [ -n "$devm" ] || { echo "ERROR: pane split failed (devm)" >&2; exit 4; }
    HERDR_ENV=1 herdr pane rename "$devm" devm
  fi
fi
ensure_started "$devm" '/dmt-dm'

# 3) anam: create its own tab
p="$(pane_by_label anam || true)"
if [ -z "$p" ]; then
  # Idempotence is judged by tab label: if an anam tab already exists (pane label drift), take that
  # tab's pane and rename it, do not create a second tab
  tab="$(HERDR_ENV=1 herdr tab list --workspace "$HERDR_WORKSPACE_ID" | jq -r '.result.tabs[] | select(.label=="anam") | .tab_id' | head -1)"
  if [ -n "$tab" ]; then
    p="$(HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" | jq -r --arg t "$tab" '.result.panes[] | select(.tab_id==$t) | .pane_id' | head -1)"
    h env HERDR_ENV=1 herdr pane rename "$p" anam
  elif [ "$DRY" = 1 ]; then
    echo "+ herdr tab create --workspace $HERDR_WORKSPACE_ID --cwd $PWD --label anam" >&2
    echo "+ herdr pane rename <anam-pane> anam" >&2
    p="<anam-pane>"
  else
    p="$(HERDR_ENV=1 herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label anam | jq -r '.result.root_pane.pane_id // empty')"
    [ -n "$p" ] || { echo "ERROR: tab create failed (anam)" >&2; exit 4; }
    HERDR_ENV=1 herdr pane rename "$p" anam
  fi
fi
ensure_started "$p" '/dmt-am'
echo "team ready: director / devm (right of the director tab) / anam (own tab); product work is dispatched by director itself to pde{n} sub-agents (/dmt-pde), taking no pane"
