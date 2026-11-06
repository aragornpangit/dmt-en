#!/usr/bin/env bash
# director 用：一键拉起 dmt 团队（幂等，可分阶段跳过）
# 用法：bash launch.sh [项目根目录] [选项]（项目根默认当前目录）
#   --copy          技能改为复制安装（默认软链）
#   --skip-skills   跳过技能安装
#   --skip-team     跳过建团队 pane（无 herdr 环境时也会自动跳过）
#   --skip-hooks    跳过 git hooks 安装（默认安装 core.hooksPath 守卫）
#   --dry-run       只打印将执行的动作，不实际执行
# 阶段（顺序固定）：① install-skills → ② init-project → ③ install-git-hooks → ④ setup-team
# （hooks / 派发账本机制已于 2026-11-02 随「取消 max-subagents」裁定整体删除，不再安装；2026-11-04 裁定改为「无依赖任务一律开满 subagents 并行」，但饱和机制脚本不恢复）
# 请在目标项目根执行：bash dmt-director/scripts/launch.sh [项目根目录]（省略参数＝当前目录）。
set -eu
ROOT="."
COPY=0; DOSKILLS=1; DOTEAM=1; DOHOOKS=1; DRY=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --copy) COPY=1 ;;
    --skip-skills) DOSKILLS=0 ;;
    --skip-team) DOTEAM=0 ;;
    --skip-hooks) DOHOOKS=0 ;;
    --dry-run) DRY=1 ;;
    -*) echo "unknown option: $a" >&2; exit 2 ;;
    *) ARGS+=("$a") ;;
  esac
done
if [ "${#ARGS[@]}" -gt 0 ]; then
  ROOT="$(cd -P "${ARGS[0]}" && pwd -P)"
else
  ROOT="$PWD"
fi
SCRIPT_DIR="$(cd -P "$(dirname "$0")" && pwd -P)"
# 目标根不能是技能脚本目录本身（否则 docs/、inbox/、locks/、技能全装进 scripts/）
case "$ROOT" in
  */dmt-director/scripts|*/dmt-director) echo "[launch] 目标根不能是技能目录：$ROOT" >&2; exit 2 ;;
esac

run() { echo "[launch] $*"; [ "$DRY" = 1 ] || "$@"; }

echo "[launch] 目标项目：$ROOT"
if [ "$DOSKILLS" = 1 ]; then
  if [ "$COPY" = 1 ]; then run bash "$SCRIPT_DIR/install-skills.sh" "$ROOT" --copy
  else run bash "$SCRIPT_DIR/install-skills.sh" "$ROOT"; fi
else
  echo "[launch] 跳过技能安装"
fi

run bash "$SCRIPT_DIR/init-project.sh" "$ROOT"

if [ "$DOHOOKS" = 1 ] && [ -d "$ROOT/.git" ]; then
  run bash "$SCRIPT_DIR/install-git-hooks.sh"
elif [ "$DOHOOKS" = 1 ]; then
  echo "[launch] 目标不是 git 仓（无 .git），跳过 git hooks 安装"
else
  echo "[launch] 跳过 git hooks 安装"
fi

if [ "$DOTEAM" = 1 ]; then
  # 建团队守卫：四个 herdr 变量齐备才建（缺一则 setup-team.sh 会在 : "$VAR" 处直接断掉）
  missing=""
  [ -n "${HERDR_ENV:-}" ] || missing="$missing HERDR_ENV"
  [ -n "${HERDR_PANE_ID:-}" ] || missing="$missing HERDR_PANE_ID"
  [ -n "${HERDR_TAB_ID:-}" ] || missing="$missing HERDR_TAB_ID"
  [ -n "${HERDR_WORKSPACE_ID:-}" ] || missing="$missing HERDR_WORKSPACE_ID"
  # 建 pane 的 cwd 取 setup-team.sh 的 $PWD，必须先进项目根再调用，否则 pane 会落在 scripts/ 目录
  if [ -z "$missing" ]; then ( cd "$ROOT" && run bash "$SCRIPT_DIR/setup-team.sh" )
  else echo "[launch] herdr 环境不齐（缺:$missing），跳过建团队；在 director pane 内重跑本脚本或直接 bash $SCRIPT_DIR/setup-team.sh"; fi
else
  echo "[launch] 跳过建团队"
fi

echo "[launch] 完成。机检：bash $SCRIPT_DIR/check-dmt.sh $ROOT ；结构化机检：bash $SCRIPT_DIR/check-dmt.sh $ROOT"
