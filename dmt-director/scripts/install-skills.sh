#!/usr/bin/env bash
# Install the dmt skills into the target project (symlink by default; --copy to copy)
# Usage: bash install-skills.sh <project-root> [--copy]
set -eu
TARGET="${1:?usage: install-skills.sh <project-root> [--copy]}"
MODE="${2:-link}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="$(cd "$TARGET" && pwd)"
SKILLS="dmt-director dmt-pm dmt-dm dmt-am dmt-dtl dmt-atl"

mkdir -p "$TARGET/.agents/skills" "$TARGET/scripts"
for s in $SKILLS; do
  if [ "$MODE" = "--copy" ]; then
    rm -rf "$TARGET/.agents/skills/$s"
    cp -r "$REPO/$s" "$TARGET/.agents/skills/$s"
  else
    ln -sfn "$REPO/$s" "$TARGET/.agents/skills/$s"
  fi
done
cp "$REPO/dmt-director/team.md" "$TARGET/docs/team.md" 2>/dev/null || { mkdir -p "$TARGET/docs"; cp "$REPO/dmt-director/team.md" "$TARGET/docs/team.md"; }
for f in "$REPO"/dmt-director/scripts/*.sh; do cp "$f" "$TARGET/scripts/"; done

bash "$TARGET/scripts/init-project.sh" "$TARGET"
echo "installed ($MODE) into $TARGET"
