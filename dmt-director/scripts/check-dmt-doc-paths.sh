#!/usr/bin/env bash
# Machine check for dmt artifact landing paths (checks "projects that use this team")
# Criteria source: this repo's team.md §3 "single landing location (hard constraint)", §1 org, §5 parallel policy
# Usage: bash dmt-director/scripts/check-dmt-doc-paths.sh [project-root]    defaults to current directory
#     Env var DMT_SKILLS_DIR can override the skill install location (default <project-root>/.agents/skills)
set -u

ROOT="$(cd "${1:-$PWD}" && pwd)" || exit 2
SKILLS_DIR="${DMT_SKILLS_DIR:-$ROOT/.agents/skills}"
# Contract lookup: prefer the project's docs/team.md, fall back to one level above the script's real location (when the script sits next to this repo's team.md)
if [ -f "$ROOT/docs/team.md" ]; then
  CONTRACT="$ROOT/docs/team.md"
else
  CONTRACT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)/team.md"
fi

# Six artifact dirs (under docs) + inbox root (under project root, not inside docs/)
DOC_DIRS="docs/pd/prd docs/pd/spec docs/dev/tickets docs/analyst docs/human/human-arch docs/human/human-plan"

fail=0
echo "Project root:  $ROOT"
echo "Skills dir:    $SKILLS_DIR"
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
echo "== 2) The six role skills must point to their own unique dir (PRD / SPEC / tickets / human docs belong to dmt-pm) =="
check() {
  local file="$1" want="$2" who="${3:-}"
  [ -n "$who" ] || who="$(basename "$(dirname "$file")")"
  if [ ! -f "$file" ]; then
    echo "FAIL not found            $who ($file)"
    fail=1
    return
  fi
  if grep -q -- "$want" "$file"; then
    echo "OK   $who contains $want"
  else
    echo "FAIL $who missing $want"
    fail=1
  fi
}
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'docs/pd/prd/'
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'docs/pd/spec/'
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'to-tickets'
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'docs/human/human-arch/'
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'docs/human/human-plan/'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'docs/team.md'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'docs/analyst/'
check "$SKILLS_DIR/dmt-dtl/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/dmt-atl/SKILL.md" 'docs/analyst/'

echo
echo "== 2b) Org ownership: director manages pm/devm/anam; pm has no leader tier and uses sub-agents only =="
check "$SKILLS_DIR/dmt-director/SKILL.md" 'pm' 'director'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'setup-team.sh' 'director'
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'sub-agent' 'dmt-pm'
check "$CONTRACT" '| `dmt-pm` | `pm` |' 'team contract'

echo
echo "== 3) Leader instance close actions must be registered (close when done; only the creator may close; close pane only, not tab) =="
check "$CONTRACT" 'close-leader.sh' 'team contract'
check "$CONTRACT" 'never close before collecting' 'team contract'
check "$CONTRACT" 'only panes may be closed' 'team contract'   # the rule itself: close pane only ('herdr tab close' also appears in the §8 history, so it cannot be used as the criterion)
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'close-leader.sh' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'close-leader.sh' 'anam'

echo
echo "== 3b) Identity must be resolved by pane label (not by position inside the tab) =="
check "$CONTRACT" 'pane label' 'team contract'
check "$CONTRACT" 'not by position within a tab' 'team contract'
for role in dmt-director dmt-pm dmt-dm dmt-am dmt-dtl dmt-atl; do
  check "$SKILLS_DIR/$role/SKILL.md" 'pane label' "$role"
done

echo
echo "== 4) Leader-tier parallel criteria must be registered (no deps ≥2 ⇒ dispatch concurrently) =="
check "$SKILLS_DIR/dmt-dtl/SKILL.md" 'must run in parallel' 'devtl'
check "$SKILLS_DIR/dmt-atl/SKILL.md" 'must run in parallel' 'anatl'
check "$CONTRACT" '≥2 ⇒ must be dispatched concurrently' 'team contract'

echo
echo "== 4b) Manager-tier path criteria and saturated dispatch must be registered (devm ≤4 / anam ≤4) =="
check "$SKILLS_DIR/dmt-dm/SKILL.md" '≤4' 'devm'
check "$SKILLS_DIR/dmt-dm/SKILL.md" '>4' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" '≤4' 'anam'
check "$SKILLS_DIR/dmt-am/SKILL.md" '>4' 'anam'
check "$CONTRACT" '≤4 ⇒ derive `dev-e` itself' 'team contract'
check "$CONTRACT" '≤4 ⇒ derive `ana-e` itself' 'team contract'
check "$CONTRACT" 'concurrency = number of units' 'team contract'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'saturat' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'saturat' 'anam'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'teammate' 'devm'
check "$SKILLS_DIR/dmt-am/SKILL.md" 'teammate' 'anam'

echo
echo "== 4c) Doorbell channels must be registered (the five harnesses prefer agent prompt, others fall back) =="
check "$CONTRACT" 'opencode2' 'team contract'
check "$CONTRACT" 'agent prompt' 'team contract'

echo
echo "== 4d) Install and push belong to director only (one push per ticket; hourly patrol) =="
check "$CONTRACT" 'only the director can execute' 'team contract'
check "$CONTRACT" 'only the director may execute' 'team contract'
check "$CONTRACT" 'push at least once per completed ticket' 'team contract'
check "$CONTRACT" 'at least hourly' 'team contract'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'git push' 'director'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'does not push' 'devm'

echo
echo "== 4e) mattpocock mandatory skills must be registered per role =="
check "$CONTRACT" 'mandatory' 'team contract'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/grilling' 'director'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/code-review' 'director'
check "$SKILLS_DIR/dmt-pm/SKILL.md" '/to-spec' 'pm'
check "$SKILLS_DIR/dmt-pm/SKILL.md" '/to-tickets' 'pm'
check "$SKILLS_DIR/dmt-dm/SKILL.md" '/code-review' 'devm'
check "$SKILLS_DIR/dmt-dtl/SKILL.md" '/tdd' 'devtl'
check "$SKILLS_DIR/dmt-atl/SKILL.md" '/research' 'anatl'
check "$SKILLS_DIR/dmt-atl/SKILL.md" '/rea' 'anatl'
check "$SKILLS_DIR/dmt-dtl/SKILL.md" '/implement' 'devtl'
check "$SKILLS_DIR/dmt-director/SKILL.md" '/grill-me' 'director'
check "$SKILLS_DIR/dmt-pm/SKILL.md" '/grill-me' 'pm'
check "$SKILLS_DIR/dmt-pm/SKILL.md" '/grill-with-docs' 'pm'
check "$SKILLS_DIR/dmt-am/SKILL.md" '/grill-me' 'anam'
check "$SKILLS_DIR/dmt-am/SKILL.md" '/grill-with-docs' 'anam'

echo
echo "== 4f) File claims (check before editing) must be registered =="
check "$CONTRACT" 'file claims' 'team contract'
check "$CONTRACT" 'file-claim' 'team contract'
for role in dmt-director dmt-pm dmt-dm dmt-am dmt-dtl dmt-atl; do
  check "$SKILLS_DIR/$role/SKILL.md" 'file-claim' "$role"
done
if [ -f "$(dirname "$(readlink -f "$0")")/file-claim.sh" ]; then
  echo "OK   file-claim.sh present"
else
  echo "FAIL missing file-claim.sh"
  fail=1
fi

echo
echo "== 4g) Review gate ownership (docs to pm / code to devm) =="
check "$CONTRACT" 'document gate' 'team contract'
check "$CONTRACT" 'code gate' 'team contract'
check "$SKILLS_DIR/dmt-pm/SKILL.md" 'document gate' 'pm'
check "$SKILLS_DIR/dmt-dm/SKILL.md" 'code gate' 'devm'
check "$SKILLS_DIR/dmt-director/SKILL.md" 'does not replace' 'director'

echo
echo "== 4h) The cbc-herdr common skill must be registered per role =="
for role in dmt-director dmt-pm dmt-dm dmt-am dmt-dtl dmt-atl; do
  check "$SKILLS_DIR/$role/SKILL.md" 'cbc-herdr' "$role"
done

echo
echo "== 4i) mattpocock skill names must match upstream and carry raw links =="
check "$CONTRACT" 'raw.githubusercontent.com' 'team contract'
for role in dmt-director dmt-pm dmt-dm dmt-am dmt-dtl dmt-atl; do
  check "$SKILLS_DIR/$role/SKILL.md" 'raw.githubusercontent.com' "$role"
done

echo
echo "== 4j) Deterministic actions must be scripted (scripts complete and executable) =="
for s in init-project.sh setup-team.sh spawn-leader.sh close-leader.sh send-msg.sh msg-take.sh msg-done.sh dispatch-ledger.sh self-work-guard.sh install-hooks.sh publish.sh file-claim.sh install-skills.sh check-dmt-doc-paths.sh; do
  f="$(dirname "$(readlink -f "$0")")/$s"
  if [ -x "$f" ]; then echo "OK   $s"; else echo "FAIL $s missing or not executable"; fail=1; fi
done

echo
echo "== 4k) The three-state inbox must be registered (claim .doing/, delete when done, .seq high-water) =="
check "$CONTRACT" '.doing/' 'team contract'
check "$CONTRACT" '.seq' 'team contract'
check "$CONTRACT" 'msg-take.sh' 'team contract'
check "$CONTRACT" 'msg-done.sh' 'team contract'
for role in dmt-director dmt-pm dmt-dm dmt-am dmt-dtl dmt-atl; do
  check "$SKILLS_DIR/$role/SKILL.md" 'msg-take.sh' "$role"
done

echo
echo "== 4l) Dispatch-first and the concurrency ledger must be registered =="
check "$CONTRACT" 'dispatch first' 'team contract'
check "$CONTRACT" 'concurrency ledger' 'team contract'
check "$CONTRACT" 'Dispatch compliance' 'team contract'
for role in dmt-pm dmt-dm dmt-am; do
  check "$SKILLS_DIR/$role/SKILL.md" 'dispatch first' "$role"
  check "$SKILLS_DIR/$role/SKILL.md" 'concurrency ledger' "$role"
done
check "$SKILLS_DIR/dmt-director/SKILL.md" 'concurrency ledger' 'director'

echo
echo "== 5) The team contract must register the six unique dirs and the inbox root =="
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
echo "== 6) Negative sample: the criteria must reject a bad path (expect rc=1) =="
# Only inspect the "single landing location" registry (§3 table rows) — historical traces in the §8 change log do not count as registration
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
