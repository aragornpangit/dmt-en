#!/usr/bin/env bash
# 把 dmt 技能装到目标项目（默认软链，--copy 则复制）
# 用法：bash install-skills.sh <project-root> [--copy] [--harness all|claude,codebuddy,codex,opencode,pi]
#
# 技能落点（2026-11-04 逐 harness 探针实测：各 harness 只认自己的目录，**没有"一处通用"**）：
#   .agents/skills/    ← codex / opencode / pi（pi 的项目级 .agents/skills 需 --approve 才可见）
#   .claude/skills/    ← claude（opencode 也读它）
#   .codebuddy/skills/ ← codebuddy
# 默认 --harness all ⇒ 上面三处全装（五个 harness 全覆盖）；也可只装指定 harness 的落点。
# 不必另装 codex / pi 的私有目录（.codex/skills、.pi/skills）—— 它们已经读 .agents/skills/。
#
# 契约：<target>/docs/team.md、<target>/docs/OPS.md 与 <target>/docs/ops/
# （link 模式＝软链、copy 模式＝复制，机检按同目录查找）
# 脚本与契约正本落到 <target>/dmt-director/（team.md 里的命令一律写 dmt-director/scripts/…）
set -eu

TARGET=""
MODE=link
HARNESS="all"
while [ $# -gt 0 ]; do
  case "$1" in
    --copy|copy) MODE=copy ;;
    link) MODE=link ;;
    --harness) HARNESS="${2:?missing harness list}"; shift ;;
    -*) echo "unknown arg: $1（只认 --copy 与 --harness）" >&2; exit 2 ;;
    *) TARGET="$1" ;;
  esac
  shift
done
[ -n "$TARGET" ] || { echo "usage: install-skills.sh <project-root> [--copy] [--harness all|claude,codebuddy,codex,opencode,pi]" >&2; exit 2; }

REPO="$(cd -P "$(dirname "$0")/../.." && pwd -P)"
TARGET="$(cd -P "$TARGET" && pwd -P)"
# 防自引用：target 落在技能仓内时拒绝（否则会把软链建到自身，造出 <repo>/dmt-director/dmt-director 之类残留）
case "$TARGET" in
  "$REPO"|"$REPO"/*) echo "拒绝：target 落在技能仓内（$TARGET）—— 技能仓是维护地，不是安装目标" >&2; exit 2 ;;
esac

# harness → 技能落点目录：**单一来源＝harness_matrix.yaml**（经 harness-matrix.sh 读取），
# 不再在脚本里写死 case 分支。`all` 取矩阵的 install_all_dirs。
MATRIX="$REPO/dmt-director/scripts/harness-matrix.sh"
[ -x "$MATRIX" ] || { echo "install-skills: 缺 harness-matrix.sh（无法解析落点）" >&2; exit 3; }
if [ "$HARNESS" = "all" ]; then
  out="$(bash "$MATRIX" install-dirs)" || exit 2
else
  out="$(bash "$MATRIX" install-dirs-for "$HARNESS")" || exit 2
fi
DIRS=""
for d in $out; do
  case " $DIRS " in *" $d "*) ;; *) DIRS="$DIRS $d" ;; esac
done
[ -n "$DIRS" ] || { echo "no skill dir resolved for --harness '$HARNESS'" >&2; exit 2; }

SKILLS="dmt-director dmt-dm dmt-am dmt-pde dmt-de dmt-ae dmt-reviewer"
# 历史改名遗留：旧技能名不会自动消失（软链会变断链、副本会变孤儿目录），安装时显式清理。
# 2026-11-04 第七十一次：dmt-rve → dmt-reviewer；另含更早的队长层 / 产品经理技能名。
LEGACY_SKILLS="dmt-rve dmt-pm dmt-dtl dmt-atl"
for rel in $DIRS; do
  mkdir -p "$TARGET/$rel"
  for s in $LEGACY_SKILLS; do rm -rf "$TARGET/$rel/$s"; done
  for s in $SKILLS; do
    # 目标已存在且是实体目录（旧版复制/旧落点）时必须先删，否则 ln -sfn 会把软链建到目录里面
    rm -rf "$TARGET/$rel/$s"
    if [ "$MODE" = "copy" ]; then
      cp -r "$REPO/$s" "$TARGET/$rel/$s"
    else
      ln -sfn "$REPO/$s" "$TARGET/$rel/$s"
    fi
  done
  echo "skills -> $TARGET/$rel ($MODE)"
done

# 脚本目录固定为 <target>/dmt-director/scripts/ —— 与契约里所有命令写法一致。
# 旧版曾复制到 <target>/scripts/，从项目根执行 $TARGET/scripts/… 会 rc=127（已废弃）。
if [ "$MODE" = "copy" ]; then
  rm -rf "$TARGET/dmt-director"
  cp -r "$REPO/dmt-director" "$TARGET/dmt-director"
elif [ -e "$TARGET/dmt-director" ] && [ ! -L "$TARGET/dmt-director" ]; then
  echo "WARN: $TARGET/dmt-director 已存在且不是软链，沿用现有目录" >&2
else
  ln -sfn "$REPO/dmt-director" "$TARGET/dmt-director"
fi
chmod +x "$TARGET/dmt-director/scripts/"*.sh 2>/dev/null || true

mkdir -p "$TARGET/docs"
# 契约落到 docs/team.md（OPS 同理落到 docs/OPS.md，机检按同目录查找）：
#   · link 模式（默认）＝**软链** → 跟随 <target>/dmt-director/ 下的正本，正本变更自动生效；
#   · copy 模式＝**复制** → 目标项目不跟随本仓（正本变更后需重跑本脚本，见 README「维护」）。
rm -f "$TARGET/docs/team.md" "$TARGET/docs/OPS.md"
if [ "$MODE" = "copy" ]; then
  # 只替换 DMT 拥有的入口；目标项目自己的 docs 子目录保留。
  rm -rf "$TARGET/docs/ops" "$TARGET/docs/team" "$TARGET/docs/changelog" "$TARGET/docs/harness"
  rm -f "$TARGET/docs/CHANGELOG.md" "$TARGET/docs/CHANGELOG-DIGEST.md"
  mkdir -p "$TARGET/docs/ops"
  cp "$TARGET/dmt-director/team.md" "$TARGET/docs/team.md"
  cp "$TARGET/dmt-director/OPS.md"  "$TARGET/docs/OPS.md"
  cp "$TARGET/dmt-director/ops/"*.md "$TARGET/docs/ops/"
  cp -r "$TARGET/dmt-director/team" "$TARGET/docs/team"
  cp -r "$TARGET/dmt-director/harness" "$TARGET/docs/harness"
  cp "$TARGET/dmt-director/CHANGELOG.md" "$TARGET/dmt-director/CHANGELOG-DIGEST.md" "$TARGET/docs/"
  cp -r "$TARGET/dmt-director/changelog" "$TARGET/docs/changelog"
else
  # 软链模式可能从旧的穿插安装切换而来；先移除文档入口，再补建 ops/ 与 harness/。
  rm -rf "$TARGET/docs/ops" "$TARGET/docs/harness"
  mkdir -p "$TARGET/docs/ops"
  ln -sfn ../dmt-director/harness "$TARGET/docs/harness"
  ln -sfn ../dmt-director/team.md "$TARGET/docs/team.md"
  ln -sfn ../dmt-director/OPS.md  "$TARGET/docs/OPS.md"
  for f in "$TARGET/dmt-director/ops/"*.md; do
    ln -sfn "../../dmt-director/ops/$(basename "$f")" "$TARGET/docs/ops/$(basename "$f")"
  done
  ln -sfn ../dmt-director/team "$TARGET/docs/team"
  ln -sfn ../dmt-director/CHANGELOG.md "$TARGET/docs/CHANGELOG.md"
  ln -sfn ../dmt-director/CHANGELOG-DIGEST.md "$TARGET/docs/CHANGELOG-DIGEST.md"
  ln -sfn ../dmt-director/changelog "$TARGET/docs/changelog"
fi

# pi 子代理 agent 定义（.pi/agents/）：只装给 pi（或 all）。
# 为什么单列：pi 的 delegate 默认 inheritSkills: false ⇒ 子代理无技能清单；
# 这些定义用 inheritSkills: false + skills: 精确白名单把角色技能注入子代理（见 harness/pi.md §4.1）。
case " $HARNESS " in
  *" all "*|*" pi "*)
    mkdir -p "$TARGET/.pi/agents"
    for f in "$REPO/dmt-director/harness/pi-agents/"*.md; do
      b="$(basename "$f")"
      [ "$b" = "README.md" ] && continue
      rm -f "$TARGET/.pi/agents/$b"
      if [ "$MODE" = "copy" ]; then cp "$f" "$TARGET/.pi/agents/$b"; else ln -sfn "$f" "$TARGET/.pi/agents/$b"; fi
    done
    echo "pi agents -> $TARGET/.pi/agents ($MODE)"
    ;;
esac

# 初始化 + 机检。DMT_SKILLS_DIR 指向本次实际装的第一个落点（--harness claude 之类不含 .agents 时，
# 机检默认的 <target>/.agents/skills 并不存在，会把技能断言全部误报红）。
FIRST_DIR="$(printf '%s' "$DIRS" | awk '{print $1}')"
DMT_SKILLS_DIR="$TARGET/$FIRST_DIR" bash "$REPO/dmt-director/scripts/init-project.sh" "$TARGET"
echo "installed ($MODE, --harness $HARNESS) into $TARGET"
