#!/usr/bin/env bash
# director 用：给自己正名，建 devm（本 tab 右侧）/ anam（独立 tab）两个 pane 并代启动 harness（创建与启动都幂等）
# 用法：bash setup-team.sh [--dry-run] [--no-start] [--force-start] [--reload] [--harness <name>]
#   --no-start     只建 pane，不启动
#   --force-start  即使 agent 已在跑也重发启动命令（默认跳过：对运行中的 agent 发启动命令会被当成用户提问）
#   --reload       对已在跑的 pane 补发技能命令（重载技能，不重发启动命令；codex 在新会话重开）
#   --harness      harness 名：codebuddy（默认）| pi | opencode | codex | claude（亦可 $DMT_HARNESS；$DMT_HARNESS_CMD 整体覆盖）
#   需要环境变量 HERDR_ENV=1、HERDR_PANE_ID、HERDR_TAB_ID、HERDR_WORKSPACE_ID
set -eu
DRY=0; START=1; FORCE=0; RELOAD=0; HARNESS_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --no-start) START=0 ;;
    --force-start) FORCE=1 ;;
    --reload) RELOAD=1 ;;
    --harness) HARNESS_ARG="${2:-}"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done
missing=""
[ -n "${HERDR_ENV:-}" ] || missing="$missing HERDR_ENV"
[ -n "${HERDR_PANE_ID:-}" ] || missing="$missing HERDR_PANE_ID"
[ -n "${HERDR_TAB_ID:-}" ] || missing="$missing HERDR_TAB_ID"
[ -n "${HERDR_WORKSPACE_ID:-}" ] || missing="$missing HERDR_WORKSPACE_ID"
[ -z "$missing" ] || { echo "缺少环境变量:$missing（在 director pane 内执行本脚本）" >&2; exit 2; }

. "$(cd -P "$(dirname "$0")" && pwd -P)/lib-dmt.sh"

HARNESS="$(dmt_harness_name "$HARNESS_ARG")" || exit 2
HARNESS_CMD="$(dmt_harness_cmd "$HARNESS")" || exit 2
FIRST_PROMPT=0
if dmt_start_has_first_prompt "$HARNESS"; then FIRST_PROMPT=1; fi

h() { if [ "$DRY" = 1 ]; then echo "+ $*" >&2; else "$@"; fi; }
pane_by_label() { dmt_pane_by_label "$1"; }
# agent_status: unknown = 该 pane 没有 agent 在跑；idle/working/blocked = 已在跑
pane_status() { dmt_pane_status "$1"; }
# 就绪判据：轮询 agent_status 不再是 unknown。
# 不要用 wait-output 匹配屏幕文字 —— 对已在跑的 pane 它会立刻命中历史输出，等于没有判据。
wait_ready() { dmt_wait_ready "$1" 60 || true; }
ensure_started() {
  local pane="$1" skill_name="$2" role="$3" st prompt
  prompt="$(dmt_skill_prompt "$HARNESS" "$skill_name" '' "$role")"
  [ "$START" = 1 ] || { echo "skip start: $pane"; return 0; }
  if [ "$DRY" = 1 ]; then
    if [ "$FIRST_PROMPT" = 1 ]; then
      echo "+ [dry] start $pane: $HARNESS_CMD '<角色技能 prompt>' (harness=$HARNESS, first prompt)" >&2
    else
      echo "+ [dry] start $pane: $HARNESS_CMD (harness=$HARNESS)  then  $(dmt_skill_cmd "$HARNESS" "$skill_name")" >&2
    fi
    return 0
  fi
  st="$(pane_status "$pane")"
  if [ "$st" != "unknown" ] && [ "$FORCE" != 1 ]; then
    echo "already running (agent_status=$st): $pane -- 不重发启动命令"
    if [ "$RELOAD" = 1 ]; then
      if [ "$FIRST_PROMPT" = 1 ]; then
        echo "WARN codex 的首轮 prompt 只在启动时生效；技能重载须重开 pane: $pane" >&2
      else
        h env HERDR_ENV=1 herdr pane send-text "$pane" "$(dmt_skill_cmd "$HARNESS" "$skill_name")"
        h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
        echo "reloaded skill on $pane"
      fi
    fi
    return 0
  fi
  if [ "$FIRST_PROMPT" = 1 ]; then
    # Codex 首次会话可能先出 trust/启动界面；技能必须与启动命令同一次提交，
    # 否则第二次粘贴会落进确认界面而不是成为会话 prompt。
    h env HERDR_ENV=1 DMT_PANE_ROLE="$role" herdr pane send-text "$pane" \
      "DMT_PANE_ROLE=$role $HARNESS_CMD '$prompt'"
    h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
    wait_ready "$pane" || true
  else
    h env HERDR_ENV=1 herdr pane send-text "$pane" "$HARNESS_CMD"
    h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
    wait_ready "$pane" || true
    h env HERDR_ENV=1 herdr pane send-text "$pane" "$(dmt_skill_cmd "$HARNESS" "$skill_name")"
    h env HERDR_ENV=1 herdr pane send-keys "$pane" enter
  fi
  # 档位复验（第六十三次）：就绪只证明「有 agent 在跑」，不证明它跑在自动档。
  # 非自动档的 pane 每次工具调用都要人点批准 —— 表现为「脚本超时/命令失败」，根因却在权限层。
  verify_auto_mode "$pane"
}

# 启动后回读 argv 复验自动档；rc=1 告警并把该 pane 标出来，不静默放过。
# argv 拿不到（rc=2，如 herdr process-info 不可用）只记 INFO —— 不把工具限制当违规。
verify_auto_mode() {
  local pane="$1" rc=0
  dmt_pane_auto_mode "$pane" || rc=$?
  case "$rc" in
    0) echo "auto-mode OK: $pane" ;;
    2) echo "INFO 无法判定权限档位（拿不到 argv）: $pane" >&2 ;;
    *) echo "WARN $pane 不在自动批准档位 —— 每次工具调用都可能撞审批；请用 --harness/--force-start 重开该 pane（argv: $(dmt_pane_argv "$pane")）" >&2 ;;
  esac
  return 0
}

# 1) 自己正名：先 tab 后 pane
h env HERDR_ENV=1 herdr tab rename "$HERDR_TAB_ID" director
h env HERDR_ENV=1 herdr pane rename "$HERDR_PANE_ID" director

# 2) devm：在 director pane 右侧 split（与 director 同 tab，左 director 右 devm）
devm="$(pane_by_label devm || true)"
if [ -z "$devm" ]; then
  if [ "$DRY" = 1 ]; then
    echo "+ herdr pane split $HERDR_PANE_ID --direction right --cwd $PWD --no-focus" >&2
    echo "+ herdr pane rename <devm-pane> devm" >&2
    devm="<devm-pane>"
  else
    devm="$(HERDR_ENV=1 herdr pane split "$HERDR_PANE_ID" --direction right --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id // empty')"
    [ -n "$devm" ] || { echo "ERROR: pane split 失败（devm）" >&2; exit 4; }
    HERDR_ENV=1 herdr pane rename "$devm" devm
  fi
fi
ensure_started "$devm" dmt-dm devm

# 3) anam：独立建 tab
p="$(pane_by_label anam || true)"
if [ -z "$p" ]; then
  # 幂等按 tab label 判：已有 anam tab（pane label 漂移）⇒ 取该 tab 的 pane 改名，不再建第二个 tab
  tab="$(HERDR_ENV=1 herdr tab list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null | jq -r '.result.tabs[]? | select(.label=="anam") | .tab_id' 2>/dev/null | head -1 || true)"
  if [ -n "$tab" ]; then
    p="$(HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null | jq -r --arg t "$tab" '.result.panes[]? | select(.tab_id==$t) | .pane_id' 2>/dev/null | head -1 || true)"
    h env HERDR_ENV=1 herdr pane rename "$p" anam
  elif [ "$DRY" = 1 ]; then
    echo "+ herdr tab create --workspace $HERDR_WORKSPACE_ID --cwd $PWD --label anam" >&2
    echo "+ herdr pane rename <anam-pane> anam" >&2
    p="<anam-pane>"
  else
    p="$(HERDR_ENV=1 herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label anam | jq -r '.result.root_pane.pane_id // empty')"
    [ -n "$p" ] || { echo "ERROR: tab create 失败（anam）" >&2; exit 4; }
    HERDR_ENV=1 herdr pane rename "$p" anam
  fi
fi
ensure_started "$p" dmt-am anam
echo "team ready: director / devm（director tab 右侧）/ anam（独立 tab）；产品工作由 director 自派 pde{n} 子代理（/dmt-pde），不占 pane"
