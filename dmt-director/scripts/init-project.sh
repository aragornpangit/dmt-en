#!/usr/bin/env bash
# Initialize the served project's directories and .gitignore, then run one machine check (idempotent)
# Usage: bash init-project.sh [project-root] (defaults to current directory)
set -eu
ROOT="$(cd "${1:-$PWD}" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$ROOT"/docs/{pd/{prd,spec},dev/tickets,analyst,human/{human-arch,human-plan}} \
         "$ROOT"/inbox/{director,pm,devm,anam} "$ROOT"/locks

for line in 'inbox/*/' 'locks/'; do
  grep -qxF "$line" "$ROOT/.gitignore" 2>/dev/null || echo "$line" >> "$ROOT/.gitignore"
done

echo "initialized: $ROOT"
bash "$SCRIPT_DIR/check-dmt-doc-paths.sh" "$ROOT"
