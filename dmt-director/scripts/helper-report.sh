#!/usr/bin/env bash
# helper-report.sh —— helper 分身向主体单向汇报（补全 helper 机制的回报通道）
#
# 背景：helper 是本体纯分身，成果「单向汇报给主体」（写 inbox/<主体>/，方向 {角色}-helper2{角色}-）。
# 此前只有契约文字、没有执行脚本 —— helper 干完活无从回报，close-helper.sh 的方向过滤永远查不到
# 消息，回收门槛形同虚设（详见 README 的 helper 说明）。本脚本补上这条通道。
#
# 用法：bash helper-report.sh <主体角色> <正文文件> [--dry-run]
#   <主体角色> ∈ director | devm | anam（helper 的创建者）
#   <正文文件>  自包含的回报正文（结论 / 逐条判据读数 / 一 手出处 / 未决项）
#   无需传「发送方」—— helper 身份由 HERDR_PANE_ID 的 label（{角色}-helper）推导；
#   非 helper pane 调用会被拒绝（只有 helper 走这条单向通道）。
#
# 落点：inbox/<主体>/{seq}-{角色}-helper2{主体}-{slug}-{YYMMDDHHMM}.md
#   方向码固定 {角色}-helper2{角色}（发送方主体 == 收件方，因为是「分身 → 本体」）。
# 本脚本**不发门铃**：helper 不走门铃互通、也不接受回程输入；主体靠收工扫收件箱发现回报。
set -eu

ROLE="${1:?usage: helper-report.sh <director|devm|anam> <body-file> [--dry-run]}"
BODY="${2:?usage: helper-report.sh <director|devm|anam> <body-file> [--dry-run]}"
DRY=0; [ "${3:-}" = "--dry-run" ] && DRY=1
case "$ROLE" in director|devm|anam) ;; *) echo "主体角色必须是 director|devm|anam" >&2; exit 2 ;; esac
[ -f "$BODY" ] || { echo "正文文件不存在：$BODY" >&2; exit 2; }
[ -s "$BODY" ] || { echo "正文文件为空：$BODY" >&2; exit 2; }

DIR="$(cd -P "$(dirname "$0")" && pwd -P)"; . "$DIR/lib-dmt.sh"

# 发送方身份：从 herdr pane label 推导，必须是 {主体}-helper
#   $DMT_HELPER_ROLE 是自测逃生舱（无 herdr 环境时模拟 helper 身份）
if [ -n "${DMT_HELPER_ROLE:-}" ]; then
  LABEL="${DMT_HELPER_ROLE}-helper"
else
  LABEL="$(dmt_role "" 2>/dev/null || true)"   # 空参数 ⇒ 从 $HERDR_PANE_ID 的 label 解析
fi
if [ "$LABEL" != "${ROLE}-helper" ]; then
  echo "拒绝：本脚本只由 ${ROLE}-helper 分身调用（当前 pane label='${LABEL:-空}'）" >&2
  exit 2
fi

root="$(dmt_root)"
inbox="$root/inbox/$ROLE"
[ "$DRY" = 1 ] || mkdir -p "$inbox" "$inbox/.doing"

# 取号：max(扫描 inbox 含 .doing 的最大号, .seq 高水位) + 1（与 send-msg.sh 同口径）
seq_file="$inbox/.seq"
cur="$(cat "$seq_file" 2>/dev/null || echo 0)"
case "$cur" in ''|*[!0-9]*) cur=0 ;; esac
max=0
for f in "$inbox"/*.md "$inbox/.doing"/*.md; do
  [ -e "$f" ] || continue
  n="$(basename "$f" | sed -n 's/^\([0-9]\{1,\}\)-.*/\1/p')"
  [ -n "$n" ] || continue
  n=$((10#$n))
  [ "$n" -gt "$max" ] && max="$n"
done
[ "$cur" -gt "$max" ] && max=$cur
seq_num=$((max + 1))
seq3="$(printf '%03d' "$seq_num")"

now="$(date +%y%m%d%H%M)"
slug="$(basename "$BODY" .md | tr -c 'a-z0-9-' '-' | sed 's/-\{2,\}/-/g; s/^-//; s/-$//' | cut -c1-40)"
[ -n "$slug" ] || slug="helper-report"
name="${seq3}-${ROLE}-helper2${ROLE}-${slug}-${now}.md"

if [ "$DRY" = 1 ]; then
  echo "+ cp $BODY $inbox/$name"; echo "+ printf '%d\\n' $seq_num > $seq_file"; exit 0
fi
cp "$BODY" "$inbox/$name"
printf '%d\n' "$seq_num" > "$seq_file.tmp" && mv "$seq_file.tmp" "$seq_file"
echo "reported $name（${ROLE}-helper → ${ROLE}；无门铃，主体扫收件箱收取）"
