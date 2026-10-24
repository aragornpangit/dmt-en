#!/usr/bin/env bash
# Install the dmt skills into a target project (symlink by default, --copy to copy)
# Usage: bash install-skills.sh <project-root> [--copy]
# Layout: skills -> <target>/.agents/skills/<role>/; contract -> <target>/docs/team.md;
#         scripts and the contract as-is -> <target>/dmt-director/ (every command in team.md uses dmt-director/scripts/...)
set -eu
TARGET="${1:?usage: install-skills.sh <project-root> [--copy]}"
MODE="${2:-link}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="$(cd "$TARGET" && pwd)"
SKILLS="dmt-director dmt-pm dmt-dm dmt-am dmt-dtl dmt-atl"

mkdir -p "$TARGET/.agents/skills"
for s in $SKILLS; do
  if [ "$MODE" = "--copy" ]; then
    rm -rf "$TARGET/.agents/skills/$s"
    cp -r "$REPO/$s" "$TARGET/.agents/skills/$s"
  else
    ln -sfn "$REPO/$s" "$TARGET/.agents/skills/$s"
  fi
done

# The script directory is always <target>/dmt-director/scripts/ -- matching every command in the contract.
# Older versions copied them to <target>/scripts/, so <target>/scripts/... from the project root returned rc=127 (dropped).
if [ "$MODE" = "--copy" ]; then
  rm -rf "$TARGET/dmt-director"
  cp -r "$REPO/dmt-director" "$TARGET/dmt-director"
elif [ -e "$TARGET/dmt-director" ] && [ ! -L "$TARGET/dmt-director" ]; then
  echo "WARN: $TARGET/dmt-director exists and is not a symlink; using it as is" >&2
else
  ln -sfn "$REPO/dmt-director" "$TARGET/dmt-director"
fi
chmod +x "$TARGET/dmt-director/scripts/"*.sh 2>/dev/null || true

mkdir -p "$TARGET/docs"
cp "$REPO/dmt-director/team.md" "$TARGET/docs/team.md"

bash "$TARGET/dmt-director/scripts/init-project.sh" "$TARGET"
echo "installed ($MODE) into $TARGET"
