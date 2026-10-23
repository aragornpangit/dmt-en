#!/usr/bin/env bash
# dmt output-path checker (checks "a project that uses this team")
# Criteria source: this repo's team.md §3 "single allowed location (hard rule)"
# Usage: bash director/scripts/check-dmt-doc-paths.sh [project root]    defaults to the current directory
#        DMT_SKILLS_DIR overrides the skill install location (default <project root>/.agents/skills)
set -u

ROOT="$(cd "${1:-$PWD}" && pwd)" || exit 2
SKILLS_DIR="${DMT_SKILLS_DIR:-$ROOT/.agents/skills}"
# Contract lookup: prefer the project's docs/team.md, fall back to the parent of the script's real location
if [ -f "$ROOT/docs/team.md" ]; then
  CONTRACT="$ROOT/docs/team.md"
else
  CONTRACT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)/team.md"
fi

# six output directories (under docs) + the inbox root (project root, not under docs)
DOC_DIRS="docs/pd/prd docs/pd/spec docs/dev/tickets docs/analyst docs/human/human-arch docs/human/human-plan"

fail=0
echo "project root: $ROOT"
echo "skills dir:   $SKILLS_DIR"
echo
echo "== 1) the six output directories and the root inbox/ must exist =="
for d in $DOC_DIRS; do
  if [ -d "$ROOT/$d" ]; then
    echo "OK   directory exists    $d"
  else
    echo "FAIL directory missing   $d"
    fail=1
  fi
done
if [ -d "$ROOT/inbox" ]; then
  echo "OK   directory exists    inbox/ (project root, not under docs/)"
else
  echo "FAIL directory missing   inbox/ (project root, not under docs/)"
  fail=1
fi

echo
echo "== 2) the five role skills must point at their own single directory =="
check() {
  local file="$1" want="$2" who="${3:-}"
  [ -n "$who" ] || who="$(basename "$(dirname "$file")")"
  if [ ! -f "$file" ]; then
    echo "FAIL skill not found     $who ($file)"
    fail=1
    return
  fi
  if grep -q -- "$want" "$file"; then
    echo "OK   $who contains $want"
  else
    echo "FAIL $who lacks $want"
    fail=1
  fi
}
check "$SKILLS_DIR/director/SKILL.md" 'docs/pd/prd/'
check "$SKILLS_DIR/director/SKILL.md" 'docs/pd/spec/'
check "$SKILLS_DIR/director/SKILL.md" 'docs/human/human-arch/'
check "$SKILLS_DIR/director/SKILL.md" 'docs/human/human-plan/'
check "$SKILLS_DIR/dev-m/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/ana-m/SKILL.md" 'docs/analyst/'
check "$SKILLS_DIR/dev-tl/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/ana-tl/SKILL.md" 'docs/analyst/'

echo
echo "== 3) the team-lead close action must be registered (close on completion; creator only) =="
check "$CONTRACT" 'herdr tab close' 'team contract'
check "$CONTRACT" 'close before collecting' 'team contract'
check "$SKILLS_DIR/dev-m/SKILL.md" 'herdr tab close' 'dev-m'
check "$SKILLS_DIR/ana-m/SKILL.md" 'herdr tab close' 'ana-m'

echo
echo "== 4) the team-lead parallelism criterion must be registered (independent >=2 => concurrent) =="
check "$SKILLS_DIR/dev-tl/SKILL.md" 'must run in parallel' 'dev-tl'
check "$SKILLS_DIR/ana-tl/SKILL.md" 'must run in parallel' 'ana-tl'
check "$CONTRACT" '≥2 ⇒ dispatch concurrently' 'team contract'

echo
echo "== 4b) the manager staffing mode must be registered (self-run / delegated) =="
check "$SKILLS_DIR/dev-m/SKILL.md" 'self-run' 'dev-m'
check "$SKILLS_DIR/ana-m/SKILL.md" 'self-run' 'ana-m'
check "$CONTRACT" 'staffing mode' 'team contract'

echo
echo "== 5) the contract must register the six single locations and the inbox root =="
if [ -f "$CONTRACT" ]; then
  for d in 'docs/pd/prd/' 'docs/pd/spec/' 'docs/dev/tickets/' 'docs/analyst/' 'docs/human/human-arch/' 'docs/human/human-plan/' 'inbox/'; do
    if grep -q -- "$d" "$CONTRACT"; then
      echo "OK   contract contains   $d"
    else
      echo "FAIL contract lacks      $d"
      fail=1
    fi
  done
else
  echo "FAIL team contract not found $CONTRACT"
  fail=1
fi

echo
echo "== 6) negative sample: the criteria must reject a bad path (expect rc=1) =="
# Only the §3 "single allowed location" table is inspected — historical notes in §8 do not count as registration
if grep -E '^\|' "$CONTRACT" | grep -q -- 'not-a-dmt-output-dir'; then
  echo "FAIL bad path registered as an output directory"
  fail=1
else
  echo "OK   bad path is not registered (table grep rc=1)"
fi

echo "---"
if [ "$fail" -eq 0 ]; then
  echo "ALL_PASS"
else
  echo "HAS_FAIL"
fi
exit "$fail"
