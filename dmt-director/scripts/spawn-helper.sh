#!/usr/bin/env bash
# For a primary role instance: open a helper pane ({role}-helper), start cbc on its behalf, and load the same-role skill to offload work
# Helper mechanism (user ruling): when the director/manager cannot keep up, sub-agents already in flight have hit the
#   limit min(8, cap), and there are still pending tasks
#   => find/create a helper tab (label fixed to helper, shared by the whole team, created if absent) -> split a pane
#   inside the helper tab and rename it {role}-helper
#   => start codebuddy --permission-mode auto on its behalf and type the same-role skill command (director->/dmt-director, devm->/dmt-dm, anam->/dmt-am)
# The life cycle is maintained by the creator (the primary role instance): create, rename (self-healing label drift),
# reclaim when the task is done (close-helper.sh closes the pane; the helper tab is kept for reuse)
# Exclusive actions are not handed over: installation may only be performed by director itself, and merge and push belong to devm alone
# Clone semantics (user ruling): the skill equals the primary's (director->/dmt-director, devm->/dmt-dm, anam->/dmt-am); the task is a one-shot dispatch at spawn time and accepts no further input afterward;
# results are a one-way report back to the primary (inbox/<primary>/, direction {seq}-{role}-helper2{role}-); a helper has no inbox of its own and does not receive messages
# Usage: bash spawn-helper.sh <director|devm|anam> [task-text] [--dry-run] [--no-start]
#   task-text: optional; dispatched to the clone in one-shot at startup (accepts no further input afterward)
#   idempotent: label {role}-helper already exists => echo already exists, exit 0
#   requires HERDR_ENV=1, HERDR_WORKSPACE_ID
set -eu
ROLE="${1:?usage: spawn-helper.sh <director|devm|anam> [task-text] [--dry-run] [--no-start]}"
shift || true
DRY=0; START=1; TASK=""
for a in "$@"; do
  case "$a" in --dry-run) DRY=1 ;; --no-start) START=0 ;; -*) echo "unknown arg: $a" >&2; exit 2 ;; *) if [ -z "$TASK" ]; then TASK="$a"; else echo "unknown arg: $a" >&2; exit 2; fi ;; esac
done
case "$ROLE" in director|devm|anam) ;; *) echo "role must be director|devm|anam" >&2; exit 2 ;; esac
LABEL="${ROLE}-helper"
case "$ROLE" in
  director) SKILL='/dmt-director' ;;
  devm) SKILL='/dmt-dm' ;;
  anam) SKILL='/dmt-am' ;;
esac

. "$(cd "$(dirname "$0")" && pwd)/lib-dmt.sh"

h() { if [ "$DRY" = 1 ]; then echo "+ $*" >&2; else "$@"; fi; }
# Query helpers: failures yield empty (so dry-run / no-herdr environments can still walk every branch and print)
q() { HERDR_ENV=1 herdr "$@" 2>/dev/null || true; }
list_panes() { q pane list --workspace "${HERDR_WORKSPACE_ID:-}"; }
pane_by_label() { dmt_pane_by_label "$1"; }
pane_status() { dmt_pane_status "$1"; }
# Readiness signal: poll agent_status until it is no longer unknown (same signal as setup-team.sh)
wait_ready() { dmt_wait_ready "$1" 60 || true; }
start_pane() {
  local pane="$1"
  [ "$START" = 1 ] || { echo "skip start: $pane"; return 0; }
  if [ "$DRY" = 1 ]; then
    echo "+ [dry] start $pane: codebuddy --permission-mode auto  then  $SKILL" >&2
    [ -z "$TASK" ] || echo "+ [dry] task -> $pane (one-shot dispatch, accepts no further input afterward): $(printf '%s\n' "$TASK" | head -1)" >&2
    return 0
  fi
  local st; st="$(pane_status "$pane")"
  if [ "$st" != "unknown" ]; then
    echo "already running (agent_status=$st): $pane -- start command not resent"
    return 0
  fi
  h env HERDR_ENV=1 herdr pane send-text "$pane" 'codebuddy --permission-mode auto'
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
  wait_ready "$pane" || true
  h env HERDR_ENV=1 herdr pane send-text "$pane" "$SKILL"
  h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
  if [ -n "$TASK" ]; then
    # The task is a one-shot dispatch: no further input is sent to this pane afterward
    h env HERDR_ENV=1 herdr pane send-text "$pane" "$TASK"
    h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
  fi
}

# 1) Idempotent: helper pane already exists => do not recreate
existing="$(pane_by_label "$LABEL")"
if [ -n "$existing" ]; then
  echo "$LABEL already exists ($existing)"
  exit 0
fi

# 2) Find/create the helper tab (label fixed to helper, shared by the whole team)
TAB="$(q tab list --workspace "${HERDR_WORKSPACE_ID:-}" \
  | jq -r '.result.tabs[]? | select(.label=="helper") | .tab_id' 2>/dev/null | head -1 || true)"
ROOT_PANE=""
if [ -z "$TAB" ]; then
  if [ "$DRY" = 1 ]; then
    echo "+ herdr tab create --workspace ${HERDR_WORKSPACE_ID:-} --cwd $PWD --label helper" >&2
    TAB="<helper-tab>"; ROOT_PANE="<helper-tab-root>"
  else
    out="$(HERDR_ENV=1 herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label helper)"
    TAB="$(printf '%s' "$out" | jq -r '.result.tab.tab_id // empty')"
    ROOT_PANE="$(printf '%s' "$out" | jq -r '.result.root_pane.pane_id // empty')"
  fi
  echo "created helper tab $TAB"
fi

# 3) Anchor pane inside the helper tab (new tab uses its root pane; an existing tab uses one of its panes to split)
base="$ROOT_PANE"
if [ -z "$base" ]; then
  base="$(list_panes | jq -r --arg t "$TAB" '.result.panes[]? | select(.tab_id==$t) | .pane_id' 2>/dev/null | head -1 || true)"
fi
if [ -z "$base" ]; then
  if [ "$DRY" = 1 ]; then
    echo "(dry) no pane yet in helper tab $TAB; continuing with a placeholder pane" >&2
    base="<helper-tab-pane>"
  else
    echo "helper tab $TAB has no anchor pane to split" >&2
    exit 3
  fi
fi

# 4) Split a pane and rename it {role}-helper
if [ "$DRY" = 1 ]; then
  h herdr pane split "$base" --direction right --cwd "$PWD" --no-focus
  h herdr pane rename "<new-pane>" "$LABEL"
  pane="<new-pane>"
else
  pane="$(HERDR_ENV=1 herdr pane split "$base" --direction right --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')"
  HERDR_ENV=1 herdr pane rename "$pane" "$LABEL"
fi

# 5) Start the harness on its behalf and load the same-role skill to offload work
start_pane "$pane"
echo "spawned $LABEL ($pane) on tab $TAB"
