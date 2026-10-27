#!/usr/bin/env bash
# dmt artifact landing-path machine check (checks "projects that use this team")
# Criteria source: this repo's team.md §1 (organization / pane / communication / skills / claims), §3 landing registration, §5 (Git / parallelism / gates), §7 machine-check list
# Usage: bash dmt-director/scripts/check-dmt-doc-paths.sh [project-root]    defaults to the current directory
#     Env var DMT_SKILLS_DIR overrides the skill install location (default <project-root>/.agents/skills)
set -u

ROOT="$(cd "${1:-$PWD}" && pwd)" || exit 2
SKILLS_DIR="${DMT_SKILLS_DIR:-$ROOT/.agents/skills}"
# Contract lookup: prefer the project's docs/team.md (installed copy); fall back to the repo's own contract
# only when this script itself lives in the skill repo at $ROOT.
# The fallback must not be unconditional: otherwise, when the target project has no contract, the skill
# repo's team.md would stand in for it and the machine check would report a false green.
CONTRACT="$ROOT/docs/team.md"
if [ ! -f "$CONTRACT" ] && [ "$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)" = "$ROOT" ]; then
  CONTRACT="$ROOT/dmt-director/team.md"
fi

# The six artifact dirs (under docs) + the inbox root (at the project root, not inside docs/)
DOC_DIRS="docs/pd/prd docs/pd/spec docs/dev/tickets docs/analyst docs/human/human-arch docs/human/human-plan"

fail=0
echo "Project root:  $ROOT"
echo "Skills dir:    $SKILLS_DIR"
echo "Contract:      $CONTRACT"
for r in dmt-director dmt-pde dmt-dm dmt-am; do
  if [ -L "$SKILLS_DIR/$r" ]; then echo "WARN skill is a symlink (validating the skill repo itself): $SKILLS_DIR/$r"; break; fi
done
echo
echo "== 1) The six artifact dirs and the root inbox/ must exist =="
for d in $DOC_DIRS; do
  if [ -d "$ROOT/$d" ]; then
    echo "OK   dir exists            $d"
  else
    echo "FAIL dir missing           $d"
    fail=1
  fi
done
if [ -d "$ROOT/inbox" ]; then
  echo "OK   dir exists            inbox/ (project root, not under docs/)"
else
  echo "FAIL dir missing           inbox/ (project root, not under docs/)"
  fail=1
fi

echo
echo "== 2) The four skills must each point at their own unique dir (PRD / SPEC / tickets / human documents belong to dmt-director; dmt-pde is the pde{n} sub-agent skill) =="
# Negative assertion: any hit on a forbidden expression is FAIL (grep -E)
# Body only: the §7 machine-check list and the §8 change log restate the assertion literals verbatim,
# so grepping the whole file would be "self-proving".
_body() { sed -n '1,/^## 7\./p' "$1"; }
check_absent() {
  local file="$1" pat="$2" who="${3:-}"
  [ -n "$who" ] || who="$(basename "$(dirname "$file")")"
  if [ ! -f "$file" ]; then
    echo "FAIL not found            $who ($file)"
    fail=1
    return
  fi
  if _body "$file" | grep -qE -- "$pat"; then
    echo "FAIL $who contains the forbidden expression /$pat/"
    fail=1
  else
    echo "OK   $who does not contain the forbidden expression /$pat/"
  fi
}
check_row() { # check_row <file> <row-start id> <want> <who>: anchor on the table row so §7 / §8 restatements cannot stand in
  local file="$1" row="$2" want="$3" who="${4:-$2}"
  if [ ! -f "$file" ]; then echo "FAIL not found            $who ($file)"; fail=1; return; fi
  if _body "$file" | grep -F -- "| \`$row\` |" | grep -q -- "$want"; then
    echo "OK   $who row contains $want"
  else
    echo "FAIL $who row is missing $want (row anchor did not hit)"
    fail=1
  fi
}
check() {
  local file="$1" want="$2" who="${3:-}"
  [ -n "$who" ] || who="$(basename "$(dirname "$file")")"
  if [ ! -f "$file" ]; then
    echo "FAIL not found            $who ($file)"
    fail=1
    return
  fi
  if _body "$file" | grep -q -- "$want"; then
    echo "OK   $who contains $want"
  else
    echo "FAIL $who is missing $want"
    fail=1
  fi
}
check "$SKILLS_DIR/dmt-director/SKILL.md" 'docs/pd/prd/'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'docs/pd/spec/'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'to-tickets'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'docs/human/human-arch/'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'docs/human/human-plan/'
check "$SKILLS_DIR/dmt-pde/SKILL.md" 'pde{n}' 'dmt-pde'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'docs/team.md'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'docs/analyst/'
# Mutual exclusion: another role's artifact dirs must not appear in this role's skill (body only; also holds when installed as a symlink)
# Only the "must not write" dirs are checked: dmt-am must not treat PRD / tickets as its own artifacts (read-only references elsewhere do not count)
check_absent "$SKILLS_DIR/dmt-am/SKILL.md" 'docs/pd/prd/|docs/dev/tickets/' 'dmt-am boundary'

echo
echo "== 2b) Org ownership: director manages devm/anam; the product line uses only the pde{n} sub-agent =="
check "$SKILLS_DIR/dmt-director/SKILL.md" 'pde{n}' 'director'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'setup-team.sh' 'director'
check "$SKILLS_DIR/dmt-pde/SKILL.md" 'sub-agent' 'dmt-pde'
check "$CONTRACT" '| `dmt-pde` | `pde{n}` |' 'team contract'

echo
echo "== 3) The helper pure-clone semantics and the reclaim action must be registered (close when the task is done; only the creator may close; close the pane only, never the tab) =="
check "$CONTRACT" 'close-helper.sh' 'team contract'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'close-helper.sh' 'director'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'close-helper.sh' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'close-helper.sh' 'anam'
check "$CONTRACT" 'never close before collecting' 'team contract'
check "$CONTRACT" 'only panes may be closed' 'team contract'   # the rule itself: close the pane only ('herdr tab close' also appears in the §8 history, so it cannot be used as the criterion)
check "$CONTRACT" 'one-shot dispatch' 'team contract'
check "$CONTRACT" 'accepts no further input' 'team contract'
check "$CONTRACT" 'one-way report' 'team contract'
check "$CONTRACT" 'has no inbox of its own' 'team contract'
check "$(dirname "$(readlink -f "$0")")/spawn-helper.sh" 'one-shot dispatch' 'spawn-helper.sh'

echo
echo "== 3b) Identity must be resolved by pane label (not by position within a tab) =="
check "$CONTRACT" 'pane label' 'team contract'
check "$CONTRACT" 'not by position within a tab' 'team contract'
for role in dmt-director dmt-pde dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'pane label' "$role"
done

echo
echo "== 4) The manager-layer parallelism criterion must be registered (dependency-free tasks always go to sub-agents) =="
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'must run in parallel' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'must run in parallel' 'anam'
check "$CONTRACT" 'dispatch sub-agents for every dependency-free task' 'team contract'
check "$CONTRACT" 'min(N, CAP)' 'team contract'

echo
echo "== 4b) The manager-layer path and on-demand concurrency must be registered (engineers are always spawned directly) =="
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'sub-agents directly' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'sub-agents directly' 'anam'
check "$CONTRACT" 'sub-agents directly' 'team contract'
check "$CONTRACT" 'min(8, cap)' 'team contract'
check "$CONTRACT" 'open on demand' 'team contract'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'open on demand' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'open on demand' 'anam'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'teammate' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'teammate' 'anam'

echo
echo "== 4c) The doorbell channels must be registered (the five harnesses prefer agent prompt, others fall back) =="
check "$CONTRACT" 'opencode2' 'team contract'
check "$CONTRACT" 'agent prompt' 'team contract'

echo
echo "== 4d) Installation belongs to director only; merge and push belong to devm alone (one push per ticket; hourly patrol) =="
check "$CONTRACT" 'merge and push belong to devm alone' 'team contract'
check "$CONTRACT" 'only director may execute' 'team contract'
check "$CONTRACT" 'push at least once per completed ticket' 'team contract'
check "$CONTRACT" 'at least hourly' 'team contract'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'push and merge belong to devm' 'devm'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'does not push on their behalf' 'director'
check_absent "$SKILLS_DIR/dmt-director/SKILL.md" 'git push[^.。]{0,40}only[ ]+(by[ ]+)?(the[ ]+)?director' 'director'

echo
echo "== 4e) The mattpocock mandatory skills must be registered per role =="
check "$CONTRACT" 'mandatory' 'team contract'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/grilling' 'director'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/code-review' 'director'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/to-spec' 'director'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/to-tickets' 'director'
check "$SKILLS_DIR/dmt-dm/SKILL.md" '/code-review' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" '/research' 'anam'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/grill-me' 'director'
check "$SKILLS_DIR/dmt-pde/SKILL.md" '/grilling' 'dmt-pde'
check "$SKILLS_DIR/dmt-pde/SKILL.md" '/research' 'dmt-pde'
check "$SKILLS_DIR/dmt-pde/SKILL.md" '/to-spec' 'dmt-pde'
check "$SKILLS_DIR/dmt-pde/SKILL.md" '/to-tickets' 'dmt-pde'
check "$SKILLS_DIR/dmt-am/SKILL.md" '/grill-me' 'anam'
check "$SKILLS_DIR/dmt-am/SKILL.md" '/grill-with-docs' 'anam'
# The lead-tier execution skills absorbed by the engineers (registered on the dev-e / ana-e rows of the contract role table)
check_row "$CONTRACT" 'dev-e' '/tdd' 'dev-e row'
check_row "$CONTRACT" 'dev-e' '/implement' 'dev-e row'
check_row "$CONTRACT" 'dev-e' '/code-review' 'dev-e row'
check_row "$CONTRACT" 'dev-e' '/diagnosing-bugs' 'dev-e row'
check_row "$CONTRACT" 'ana-e' '`/rea`' 'ana-e row'
check_row "$CONTRACT" 'ana-e' '/research' 'ana-e row'
check_row "$CONTRACT" 'ana-e' '/grilling' 'ana-e row'
check_row "$CONTRACT" 'ana-e' '/grill-me' 'ana-e row'
check_row "$CONTRACT" 'ana-e' '/grill-with-docs' 'ana-e row'
# reviewer{n}: acceptance must use /review (= /code-review, the same skill)
check_row "$CONTRACT" 'reviewer{n}' '/review' 'reviewer row'
check_row "$CONTRACT" 'reviewer{n}' '/code-review' 'reviewer row'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/review' 'director'

echo
echo "== 4f) File claims (check before editing) must be registered =="
check "$CONTRACT" 'file claim' 'team contract'
check "$CONTRACT" 'file-claim' 'team contract'
for role in dmt-director dmt-pde dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'file-claim' "$role"
done
if [ -f "$(dirname "$(readlink -f "$0")")/file-claim.sh" ]; then
  echo "OK   file-claim.sh present"
else
  echo "FAIL missing file-claim.sh"
  fail=1
fi

echo
echo "== 4g) Review gate ownership (document gate to director / code gate to devm) =="
check "$CONTRACT" 'document gate' 'team contract'
check "$CONTRACT" 'code gate' 'team contract'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'document gate' 'director'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'code gate' 'devm'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'does not replace' 'director'

echo
echo "== 4h) The cbc-herdr common skill must be registered per role =="
for role in dmt-director dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'cbc-herdr' "$role"
done

echo
echo "== 4i) mattpocock skill names must match upstream and carry raw links =="
check "$CONTRACT" 'raw.githubusercontent.com' 'team contract'
for role in dmt-director dmt-pde dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'raw.githubusercontent.com' "$role"
done

echo
echo "== 4i-b) Skill link text must match the upstream directory name verbatim =="
check_links() {
  local file="$1" who="${2:-$(basename "$(dirname "$file")")}" n=0 bad=0 label dir
  [ -f "$file" ] || return 0
  while IFS= read -r m; do
    label="$(printf '%s' "$m" | sed -n 's#^\[`\{0,1\}/\([a-z-]*\)`\{0,1\}\].*#\1#p')"
    dir="$(printf '%s' "$m" | sed -n 's#.*/skills/[a-z-]*/\([a-z-]*\)/SKILL\.md).*#\1#p')"
    [ -n "$label" ] && [ -n "$dir" ] || continue
    n=$((n + 1))
    if [ "$label" != "$dir" ]; then
      echo "FAIL $who link text /$label differs from upstream dir $dir"
      fail=1; bad=1
    fi
  done < <(grep -oE '\[`?/[a-z-]+`?\]\(https://raw\.githubusercontent\.com/mattpocock/skills/main/skills/[a-z-]+/[a-z-]+/SKILL\.md\)' "$file")
  [ "$bad" = 1 ] || echo "OK   $who: all $n skill link texts match the upstream dir names"
}
check_links "$CONTRACT" 'team contract'
for role in dmt-director dmt-pde dmt-dm dmt-am; do check_links "$SKILLS_DIR/$role/SKILL.md" "$role"; done

echo
echo "== 4j) Deterministic actions must be scripted (scripts complete and executable) =="
for s in lib-dmt.sh launch.sh init-project.sh setup-team.sh spawn-helper.sh close-helper.sh send-msg.sh msg-take.sh msg-done.sh dispatch-ledger.sh self-work-guard.sh parallel-guard.sh probe-cap.sh fanout.sh install-hooks.sh publish.sh file-claim.sh install-skills.sh check-dmt-doc-paths.sh; do
  f="$(dirname "$(readlink -f "$0")")/$s"
  if [ -x "$f" ]; then echo "OK   $s"; else echo "FAIL $s missing or not executable"; fail=1; fi
done

echo
echo "== 4k) The three-state inbox must be registered (claim .doing/, delete when done, .seq high-water) =="
check "$CONTRACT" '.doing/' 'team contract'
check "$CONTRACT" '.seq' 'team contract'
check "$CONTRACT" 'msg-take.sh' 'team contract'
check "$CONTRACT" 'msg-done.sh' 'team contract'
for role in dmt-director dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'msg-take.sh' "$role"
done

echo
echo "== 4l) Dispatch first, the concurrency ledger and reporting on completion must be registered =="
check "$CONTRACT" 'dispatch first' 'team contract'
check "$CONTRACT" 'concurrency ledger' 'team contract'
check "$CONTRACT" 'dispatch compliance' 'team contract'
for role in dmt-director dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'dispatch first' "$role"
  check "$SKILLS_DIR/$role/SKILL.md" 'concurrency ledger' "$role"
done
check "$CONTRACT" 'report on completion' 'team contract'
for role in dmt-director dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'report on completion' "$role"
done

echo
echo "== 4m) The team contract must carry a version and date matching the four skills =="
ver_skill="$(sed -n 's/^version: *//p' "$SKILLS_DIR/dmt-director/SKILL.md" 2>/dev/null | head -1)"
if [ -n "$ver_skill" ]; then echo "OK   director skill version  $ver_skill"; else echo "FAIL director skill has no version"; fail=1; fi
ver_doc="$(head -10 "$CONTRACT" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
if [ -n "$ver_doc" ]; then echo "OK   contract header version $ver_doc"; else echo "FAIL contract header has no version (a spot check cannot tell which version is loaded)"; fail=1; fi
if [ -n "$ver_skill" ] && [ "$ver_doc" = "$ver_skill" ]; then
  echo "OK   contract matches skills $ver_doc"
else
  echo "FAIL contract and skills differ  doc=${ver_doc:-none} skill=${ver_skill:-none}"; fail=1
fi
if head -10 "$CONTRACT" 2>/dev/null | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
  echo "OK   contract header has a date"
else
  echo "FAIL contract header has no date"; fail=1
fi
for role in dmt-pde dmt-dm dmt-am; do
  v="$(sed -n 's/^version: *//p' "$SKILLS_DIR/$role/SKILL.md" 2>/dev/null | head -1)"
  if [ -n "$v" ] && [ "$v" = "$ver_skill" ]; then echo "OK   $role version matches"; else echo "FAIL $role version differs (${v:-none})"; fail=1; fi
done

# When run from the project root, scripts/ does not exist (scripts live in dmt-director/scripts/); the contract may only use the prefixed form
# Body only (§0-§7); historical forms in the §8 change log do not count
if sed -n '1,/^## 8\./p' "$CONTRACT" 2>/dev/null | grep -q '`scripts/'; then
  echo "FAIL contract has a script path without the dmt-director/ prefix (rc=127 from the project root)"; fail=1
else
  echo "OK   all contract script paths carry the dmt-director/ prefix"
fi

echo
echo "== 5) The team contract must register the six unique directories and the inbox root =="
if [ -f "$CONTRACT" ]; then
  for d in 'docs/pd/prd/' 'docs/pd/spec/' 'docs/dev/tickets/' 'docs/analyst/' 'docs/human/human-arch/' 'docs/human/human-plan/' 'inbox/'; do
    if grep -q -- "$d" "$CONTRACT"; then
      echo "OK   contract contains      $d"
    else
      echo "FAIL contract missing       $d"
      fail=1
    fi
  done
else
  echo "FAIL team contract not found $CONTRACT"
  fail=1
fi

echo
echo "== 6) Negative sample: a bad path must not be registered as an artifact dir (negative samples do not enter the registry table) =="
# Only the registry table rows in the contract (lines starting with |) count — historical traces in the §8 change log are not registration
if grep -E '^\|' "$CONTRACT" | grep -q -- 'not-a-dmt-output-dir'; then
  echo "FAIL bad path registered as an artifact dir"
  fail=1
else
  echo "OK   bad path not registered as an artifact dir (table hit rc=1)"
fi

echo "---"
if [ "$fail" -eq 0 ]; then
  echo "ALL_PASS"
else
  echo "HAS_FAIL"
fi
exit "$fail"
