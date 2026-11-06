#!/usr/bin/env bash
# install-git-hooks.sh —— 安装 dmt 的 git hooks（工程卫生 §6：防内网地址 / 凭证入库）
#
# 做法：把 core.hooksPath 指向仓内受版本控制的 dmt-director/hooks，这样 hook 随仓分发、
# 不依赖 .git/hooks 的本地副本。
#
# 用法：bash dmt-director/scripts/install-git-hooks.sh [--uninstall] [--dry-run]
set -eu
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"
REPO="$(cd -P "$DIR/../.." && pwd -P)"
HOOKS="$REPO/dmt-director/hooks"
DRY=0; UNINSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

cd "$REPO"
[ -d "$HOOKS" ] || { echo "install-hooks: 缺 $HOOKS" >&2; exit 2; }
chmod +x "$HOOKS"/* 2>/dev/null || true

if [ "$UNINSTALL" = 1 ]; then
  if [ "$DRY" = 1 ]; then echo "+ git config --unset core.hooksPath"; else
    git config --unset core.hooksPath 2>/dev/null || true
    echo "已卸载（core.hooksPath 清除；回退到 .git/hooks）"
  fi
  exit 0
fi

if [ "$DRY" = 1 ]; then echo "+ git config core.hooksPath dmt-director/hooks"; exit 0; fi
git config core.hooksPath dmt-director/hooks
echo "已启用 dmt hooks：core.hooksPath=dmt-director/hooks（pre-commit 防内网地址 / 凭证 / .env）"
