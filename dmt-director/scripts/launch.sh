#!/usr/bin/env bash
# For director: bring up the dmt team in one shot (idempotent, stages can be skipped)
# Usage: bash launch.sh [project-root] [options] (project root defaults to the current directory)
#   --copy          install skills by copying instead of symlinking (default: symlink)
#   --user-hooks    install hooks at user level ~/.codebuddy (default: project level <root>/.codebuddy)
#   --skip-skills   skip skill installation
#   --skip-hooks    skip hook installation
#   --skip-team     skip creating the team panes (also skipped automatically without a herdr environment)
#   --dry-run       print the actions that would run without executing them
# Stages (fixed order): (1) install-skills -> (2) init-project -> (3) install-hooks -> (4) setup-team
# Run this from the target project root: bash dmt-director/scripts/launch.sh [project-root] (no argument = current directory).
set -eu
ROOT="."
COPY=0; USERHOOKS=0; DOSKILLS=1; DOHOOKS=1; DOTEAM=1; DRY=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --copy) COPY=1 ;;
    --user-hooks) USERHOOKS=1 ;;
    --skip-skills) DOSKILLS=0 ;;
    --skip-hooks) DOHOOKS=0 ;;
    --skip-team) DOTEAM=0 ;;
    --dry-run) DRY=1 ;;
    -*) echo "unknown option: $a" >&2; exit 2 ;;
    *) ARGS+=("$a") ;;
  esac
done
if [ "${#ARGS[@]}" -gt 0 ]; then
  ROOT="$(cd "${ARGS[0]}" && pwd)"
else
  ROOT="$PWD"
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# The target root must not be the skill script directory itself (otherwise docs/, inbox/, locks/ and the skills all land inside scripts/)
case "$ROOT" in
  */dmt-director/scripts|*/dmt-director) echo "[launch] target root must not be the skill directory: $ROOT" >&2; exit 2 ;;
esac

run() { echo "[launch] $*"; [ "$DRY" = 1 ] || "$@"; }

echo "[launch] target project: $ROOT"
if [ "$DOSKILLS" = 1 ]; then
  if [ "$COPY" = 1 ]; then run bash "$SCRIPT_DIR/install-skills.sh" "$ROOT" --copy
  else run bash "$SCRIPT_DIR/install-skills.sh" "$ROOT"; fi
else
  echo "[launch] skipping skill installation"
fi

run bash "$SCRIPT_DIR/init-project.sh" "$ROOT"

if [ "$DOHOOKS" = 1 ]; then
  if [ "$USERHOOKS" = 1 ]; then run bash "$SCRIPT_DIR/install-hooks.sh" --user
  else run bash "$SCRIPT_DIR/install-hooks.sh" "$ROOT"; fi
else
  echo "[launch] skipping hook installation"
fi

if [ "$DOTEAM" = 1 ]; then
  # Team-creation guard: create the team only when all four herdr variables are present (if one is missing, setup-team.sh aborts at its : "$VAR" guard)
  missing=""
  [ -n "${HERDR_ENV:-}" ] || missing="$missing HERDR_ENV"
  [ -n "${HERDR_PANE_ID:-}" ] || missing="$missing HERDR_PANE_ID"
  [ -n "${HERDR_TAB_ID:-}" ] || missing="$missing HERDR_TAB_ID"
  [ -n "${HERDR_WORKSPACE_ID:-}" ] || missing="$missing HERDR_WORKSPACE_ID"
  # The cwd of a created pane comes from setup-team.sh's $PWD, so we must cd into the project root
  # first, otherwise the pane lands inside the scripts/ directory
  if [ -z "$missing" ]; then ( cd "$ROOT" && run bash "$SCRIPT_DIR/setup-team.sh" )
  else echo "[launch] herdr environment incomplete (missing:$missing); skipping team creation. Rerun this script inside the director pane, or run bash $SCRIPT_DIR/setup-team.sh directly"; fi
else
  echo "[launch] skipping team creation"
fi

echo "[launch] done. Machine check: bash $SCRIPT_DIR/check-dmt-doc-paths.sh $ROOT"
