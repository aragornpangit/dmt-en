#!/usr/bin/env bash
# Initialize the served project's directories and .gitignore, then run one machine check (idempotent)
# Usage: bash init-project.sh [project-root] [--no-check] (defaults to the current directory)
#   --no-check only create directories and .gitignore, skip the machine check
#              (use it before the skills are installed, otherwise the check always reports HAS_FAIL)
set -eu
ROOT=""; CHECK=1
for a in "$@"; do
  case "$a" in
    --no-check) CHECK=0 ;;
    -*) echo "unknown option: $a" >&2; exit 2 ;;
    *) ROOT="$(cd "$a" && pwd)" ;;
  esac
done
[ -n "$ROOT" ] || ROOT="$PWD"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$ROOT"/docs/{pd/{prd,spec},dev/tickets,analyst,human/{human-arch,human-plan}} \
         "$ROOT"/inbox/{director,devm,anam} "$ROOT"/locks

for line in 'inbox/*/' 'locks/' '.codebuddy/'; do
  grep -qxF "$line" "$ROOT/.gitignore" 2>/dev/null || echo "$line" >> "$ROOT/.gitignore"
done

echo "initialized: $ROOT"
if [ "$CHECK" = 1 ]; then
  bash "$SCRIPT_DIR/check-dmt-doc-paths.sh" "$ROOT"
else
  echo "skip check (--no-check); after installing the skills run bash $SCRIPT_DIR/check-dmt-doc-paths.sh \"$ROOT\""
fi
