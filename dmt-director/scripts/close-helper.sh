#!/usr/bin/env bash
# 本体角色用：任务完成后回收 helper pane（只关 pane、不关 tab；helper tab 保留复用；非创建者不得代关）
# 用法：bash close-helper.sh <director|devm|anam> [--force] [--dry-run]
#   收件箱安检：只把 ^[0-9]+-{角色}-helper2{角色}- 方向的消息（含 .doing/）算该 helper 的未读/未收口
set -eu
ROLE="${1:?usage: close-helper.sh <director|devm|anam> [--force] [--dry-run]}"
shift || true
FORCE=0; DRY=0
for a in "$@"; do
  case "$a" in --force) FORCE=1 ;; --dry-run) DRY=1 ;; *) echo "unknown arg: $a" >&2; exit 2 ;; esac
done
case "$ROLE" in director|devm|anam) ;; *) echo "role must be director|devm|anam" >&2; exit 2 ;; esac
LABEL="${ROLE}-helper"

if ! list="$(dmt_herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" 2>/dev/null)"; then
  echo "ERROR: herdr pane list 失败，无法确认 $LABEL 状态（不按已关闭处理）" >&2
  exit 4
fi
pane="$(printf '%s' "$list" | jq -r --arg l "$LABEL" '.result.panes[]? | select(.label==$l) | .pane_id' 2>/dev/null | head -1 || true)"
if [ -z "$pane" ]; then
  if [ "$DRY" = 1 ] && [ -z "$list" ]; then
    echo "(dry) herdr 不可用（pane list 为空），按占位 pane 走完分支" >&2
    pane="<${LABEL}-pane>"
  else
    echo "$LABEL not found (already closed?)"
    exit 0
  fi
fi

# 收件箱定位到主工作树根（与 send-msg / msg-take 同口径；在 worktree 里跑也指回主树）
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"; . "$DIR/lib-dmt.sh"
root="$(dmt_root)"
inbox="$root/inbox/$ROLE"
# 未读按方向过滤：只把 ^[0-9]+-{角色}-helper2{角色}- 的消息（含 .doing/）算该 helper 的未读/未收口
pat="^[0-9]+-${LABEL}2${ROLE}-"
unread="$(find "$inbox" -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null | grep -E "$pat" | head -1 || true)"
doing="$(find "$inbox/.doing" -maxdepth 1 -name '*.md' -printf '%f\n' 2>/dev/null | grep -E "$pat" | head -1 || true)"
if [ "$FORCE" != 1 ] && { [ -n "$unread" ] || [ -n "$doing" ]; }; then
  echo "REFUSE: $inbox 还有 ${LABEL}2${ROLE} 方向的未读或未收口消息（未读 ${unread:-无} / 未收口 ${doing:-无}）；先处理，或加 --force" >&2
  exit 3
fi

echo "人工确认清单（关闭 $LABEL 前逐项确认）：① 回报已入账 ② worktree 已 git worktree remove（由关闭者确认）③ 未读自动判（本脚本按 ${LABEL}2${ROLE} 方向查过）"
if [ "$DRY" = 1 ]; then echo "+ herdr pane close $pane"; else
  dmt_herdr pane close "$pane"
  echo "closed $LABEL ($pane)（helper tab 保留复用）"
fi
