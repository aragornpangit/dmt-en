#!/usr/bin/env bash
# Expose Matt Pocock's explicit-only skills to Codex 0.166's public catalog.
# Codex 0.166 lists these skills in $ but does not load them when selected.
# Keep upstream files untouched; install shim copies under $CODEX_HOME/skills.
set -euo pipefail

SKILLS=(to-spec to-tickets implement)
SOURCE_ROOT="${MATTPOCOCK_SKILLS_ROOT:-$HOME/.codex/plugins/cache/mattpocock/mattpocock-skills}"
CODEX_SKILLS="${CODEX_SKILLS_DIR:-${CODEX_HOME:-$HOME/.codex}/skills}"
DRY_RUN=0

usage() {
  printf '%s\n' \
    "Usage: $0 [--dry-run] [--skills-dir DIR] [--source-root DIR]" \
    "" \
    "Install or refresh Codex-compatible copies of:" \
    "  ${SKILLS[*]}" \
    "" \
    "Environment:" \
    "  CODEX_HOME              Defaults to $HOME/.codex" \
    "  CODEX_SKILLS_DIR        Overrides the destination directory" \
    "  MATTPOCOCK_SKILLS_ROOT  Marketplace cache or extracted skills root"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skills-dir) CODEX_SKILLS="${2:?missing directory}"; shift ;;
    --source-root) SOURCE_ROOT="${2:?missing directory}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ ! -d "$SOURCE_ROOT/engineering" ]; then
  source_engineering="$(find "$SOURCE_ROOT" -path '*/skills/engineering' -type d -print 2>/dev/null | sort -V | tail -1)"
  [ -n "$source_engineering" ] && SOURCE_ROOT="$source_engineering"
fi

for skill in "${SKILLS[@]}"; do
  src="$SOURCE_ROOT/$skill"
  [ -f "$src/SKILL.md" ] || {
    printf 'missing source skill: %s\n' "$src/SKILL.md" >&2
    exit 3
  }
done

if [ "$DRY_RUN" = 1 ]; then
  printf 'source: %s\n' "$SOURCE_ROOT"
  printf 'destination: %s\n' "$CODEX_SKILLS"
fi

mkdir -p "$CODEX_SKILLS"
stage="$(mktemp -d "${TMPDIR:-/tmp}/mattpocock-codex-compat.XXXXXX")"
trap 'find "$stage" -mindepth 1 -depth -delete 2>/dev/null || true; rmdir "$stage" 2>/dev/null || true' EXIT

for skill in "${SKILLS[@]}"; do
  src="$SOURCE_ROOT/$skill"
  dst="$CODEX_SKILLS/$skill"
  staged="$stage/$skill"
  cp -a "$src" "$staged"
  mkdir -p "$staged/agents"
  metadata="$staged/agents/openai.yaml"
  if [ -f "$metadata" ]; then
    awk '
      /^[[:space:]]+allow_implicit_invocation:[[:space:]]*false[[:space:]]*$/ { next }
      { print }
    ' "$metadata" > "$staged/.openai.yaml"
    mv "$staged/.openai.yaml" "$metadata"
  fi

  if [ "$DRY_RUN" = 1 ]; then
    printf 'would install: %s -> %s\n' "$src" "$dst"
    continue
  fi

  if [ -L "$dst" ]; then
    rm -- "$dst"
  elif [ -d "$dst" ]; then
    find "$dst" -mindepth 1 -depth -delete
  elif [ -e "$dst" ]; then
    printf 'destination is not a directory: %s\n' "$dst" >&2
    exit 4
  fi
  mkdir -p "$dst"
  cp -a "$staged/." "$dst/"
  printf 'installed: %s -> %s\n' "$src" "$dst"
done

if [ "$DRY_RUN" = 0 ]; then
  printf 'Restart Codex to refresh its skill catalog.\n'
fi
