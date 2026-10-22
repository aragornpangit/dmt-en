#!/usr/bin/env bash
# dmt 产物落盘路径机检（检查「使用本团队的项目」）
# 判据来源：本仓 team.md §3「落盘唯一位置（硬约束）」
# 用法：bash director/scripts/check-pda-doc-paths.sh [项目根目录]    默认当前目录
#     环境变量 PDA_SKILLS_DIR 可覆盖技能安装位置（默认 <项目根>/.agents/skills）
set -u

ROOT="$(cd "${1:-$PWD}" && pwd)" || exit 2
SKILLS_DIR="${PDA_SKILLS_DIR:-$ROOT/.agents/skills}"
# 契约定位：优先项目内的 docs/team.md，回退到脚本真实位置的上一级（脚本与本仓 team.md 同级时）
if [ -f "$ROOT/docs/team.md" ]; then
  CONTRACT="$ROOT/docs/team.md"
else
  CONTRACT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)/team.md"
fi

# 六个产物目录（docs 下）+ 收件箱根（项目根下，不在 docs/ 内）
DOC_DIRS="docs/pd/prd docs/pd/spec docs/dev/tickets docs/research docs/user/user-arch docs/user/user-plan"

fail=0
echo "项目根：  $ROOT"
echo "技能目录：$SKILLS_DIR"
echo
echo "== 1) 六个产物目录与根目录 inbox/ 必须存在 =="
for d in $DOC_DIRS; do
  if [ -d "$ROOT/$d" ]; then
    echo "OK   目录存在            $d"
  else
    echo "FAIL 目录缺失            $d"
    fail=1
  fi
done
if [ -d "$ROOT/inbox" ]; then
  echo "OK   目录存在            inbox/（项目根，不在 docs/ 下）"
else
  echo "FAIL 目录缺失            inbox/（项目根，不在 docs/ 下）"
  fail=1
fi

echo
echo "== 2) 五个角色技能必须指向各自唯一目录 =="
check() {
  local file="$1" want="$2" who
  who="$(basename "$(dirname "$file")")"
  if [ ! -f "$file" ]; then
    echo "FAIL 技能未安装          $who（$file）"
    fail=1
    return
  fi
  if grep -q -- "$want" "$file"; then
    echo "OK   $who 含 $want"
  else
    echo "FAIL $who 缺 $want"
    fail=1
  fi
}
check "$SKILLS_DIR/director/SKILL.md" 'docs/pd/prd/'
check "$SKILLS_DIR/director/SKILL.md" 'docs/pd/spec/'
check "$SKILLS_DIR/director/SKILL.md" 'docs/user/user-arch/'
check "$SKILLS_DIR/dev-m/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/ana-m/SKILL.md" 'docs/research/'
check "$SKILLS_DIR/dev-tl/SKILL.md" 'docs/dev/tickets/'
check "$SKILLS_DIR/ana-tl/SKILL.md" 'docs/research/'

echo
echo "== 3) 团队契约必须登记六个唯一目录与收件箱根 =="
if [ -f "$CONTRACT" ]; then
  for d in 'docs/pd/prd/' 'docs/pd/spec/' 'docs/dev/tickets/' 'docs/research/' 'docs/user/user-arch/' 'docs/user/user-plan/' 'inbox/'; do
    if grep -q -- "$d" "$CONTRACT"; then
      echo "OK   契约含              $d"
    else
      echo "FAIL 契约缺              $d"
      fail=1
    fi
  done
else
  echo "FAIL 未找到团队契约      $CONTRACT"
  fail=1
fi

echo
echo "== 4) 负样本：判据必须能拒绝坏路径（期望 rc=1） =="
if grep -q -- 'docs/not-a-pda-output-dir/' "$CONTRACT"; then
  echo "FAIL 坏路径被误判为存在"
  fail=1
else
  echo "OK   坏路径被正确拒绝（grep rc=1）"
fi

echo "---"
if [ "$fail" -eq 0 ]; then
  echo "ALL_PASS"
else
  echo "HAS_FAIL"
fi
exit "$fail"
