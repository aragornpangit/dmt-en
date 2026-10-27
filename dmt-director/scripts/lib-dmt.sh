#!/usr/bin/env bash
# dmt script shared library: worktree root / role resolution / pane queries. Sourced by the other scripts, not run on its own.
# Usage: DIR="$(cd "$(dirname "$0")" && pwd)"; . "$DIR/lib-dmt.sh"
# Goal: one implementation per judgment criterion -- pasted copies had already drifted (the dry-run guard and a fail-closed fix were each missed in one place).

# Main worktree root: the parent of the git common dir (running inside a worktree still points back at the main tree); non-git directories fall back to the current directory.
dmt_root() {
  local r
  r="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "$r" ]; then
    case "$r" in */.git) r="${r%/.git}" ;; esac
    printf '%s' "$r"
  else
    git rev-parse --show-toplevel 2>/dev/null || pwd
  fi
}

# Role resolution: argument (empty or "-") => $DMT_ROLE => herdr pane label
dmt_role() {
  local r="${1:-}"
  case "$r" in ""|-) r="${DMT_ROLE:-}" ;; esac
  if [ -z "$r" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
    r="$(HERDR_ENV=1 herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" 2>/dev/null \
      | jq -r --arg p "$HERDR_PANE_ID" '.result.panes[]? | select(.pane_id==$p) | .label' 2>/dev/null | head -1 || true)"
  fi
  printf '%s' "$r"
}

# pane label -> pane id (empty when absent; also empty when herdr is unavailable)
dmt_pane_by_label() {
  HERDR_ENV=1 herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" 2>/dev/null \
    | jq -r --arg l "$1" '.result.panes[]? | select(.label==$l) | .pane_id' 2>/dev/null | head -1 || true
}

# the pane's agent_status (unknown = no agent running in that pane)
dmt_pane_status() {
  HERDR_ENV=1 herdr pane get "$1" 2>/dev/null \
    | jq -r '.result.pane.agent_status // "unknown"' 2>/dev/null || echo unknown
}

# Readiness signal: poll agent_status until it is no longer unknown.
# Do not use wait-output matching on screen text -- for a pane that is already running it matches
# historical output immediately, so it is not a readiness gate at all.
dmt_wait_ready() {
  local pane="$1" limit="${2:-60}" i=0 st
  while [ "$i" -lt "$limit" ]; do
    st="$(dmt_pane_status "$pane")"
    if [ "$st" != "unknown" ]; then echo "ready ($st): $pane"; return 0; fi
    sleep 1; i=$((i + 1))
  done
  echo "WARN: $pane still unknown after ${limit}s" >&2
  return 1
}
