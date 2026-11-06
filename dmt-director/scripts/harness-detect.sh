#!/usr/bin/env bash
# 判定「当前会话跑在哪个 harness」—— 技能加载第 0 步用它决定读哪份 harness-based 文件。
#
# 用法：bash harness-detect.sh [--pane <pane_id>] [--explain]
#   无参        = 判定本进程所在会话
#   --pane      = 判定指定 pane（诊断 / 机检自测用；不进 pane 也能查）
#   --explain   = 把判定来源打到 stderr（stdout 仍只有一行 harness 名）
# 输出：stdout 一行 harness 名（pi|codebuddy|claude|codex|opencode|unknown）
# rc：0 = 已判定；1 = unknown（**调用方必须显式处理，不得默认成某个 harness**）；2 = 参数错
#
# 判据优先级（首个命中为准，越靠前越硬）：
#   ① $DMT_HARNESS        显式覆盖（人工逃生舱；仍走白名单，非法值 rc=2）
#   ② herdr 前台进程 argv 进程事实（`herdr pane process-info`）
#   ③ 环境标记            精确变量（见下）
#   ④ 父进程链            逐级 ps（最多 5 层，argv 取前 3 个 token）；$DMT_DETECT_NO_PARENT=1 跳过（仅机检自测用）
#   ⑤ unknown             rc=1
#
# 为什么 argv 先于环境标记（2026-11-05 实测）：pi 会话会带上继承来的
# `CLAUDE_CODE_*` 兼容变量（本机实测：pi pane 里有 CLAUDE_CODE_DISABLE_*），
# 若用 `CLAUDE_CODE_*` 通配判 claude，就会把 pi 会话**误判成 claude**。
# 故环境标记一律用**精确变量**，且 argv（进程事实）优先。
# 另一实测：codebuddy pane 的前台 argv 是 `node …/bin/cbc -c`（basename `cbc`），
# 不是 `codebuddy` —— 两个名字都必须认。
set -u

PANE=""; EXPLAIN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pane) PANE="${2:-}"; shift ;;
    --explain) EXPLAIN=1 ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

note() { [ "$EXPLAIN" = 1 ] && echo "[detect] $*" >&2; return 0; }

# 名字归一化 + 白名单；非法给空串
norm() {
  case "${1:-}" in
    pi|claude|codex|opencode) printf '%s' "$1" ;;
    codebuddy|cbc)            printf 'codebuddy' ;;
    claude-code|claudecode)   printf 'claude' ;;
    *)                        printf '' ;;
  esac
}

# herdr 前台进程 argv（空格连接）；拿不到给空。$DMT_PANE_ARGV 可整体覆盖（机检逃生舱）。
pane_argv() {
  local pane="$1"
  if [ -n "${DMT_PANE_ARGV+x}" ]; then printf '%s' "$DMT_PANE_ARGV"; return 0; fi
  [ -n "$pane" ] || return 0
  local out
  if [ -n "${DMT_HERDR_SOCKET_PATH:-}" ]; then
    out="$(HERDR_SOCKET_PATH="$DMT_HERDR_SOCKET_PATH" HERDR_ENV=1 herdr pane process-info --pane "$pane" 2>/dev/null || true)"
  else
    out="$(HERDR_ENV=1 herdr pane process-info --pane "$pane" 2>/dev/null || true)"
  fi
  printf '%s' "$out" | jq -r '.result.process_info.foreground_processes[0].argv // [] | join(" ")' 2>/dev/null || true
}

# 从一段命令行里按 token 认 harness（跳过解释器与路径）
harness_of_cmdline() {
  local tok n i=0
  for tok in $1; do
    i=$((i + 1)); [ "$i" -gt 3 ] && break
    n="$(basename "$tok" 2>/dev/null || printf '%s' "$tok")"
    case "$n" in
      pi|claude|cbc|codebuddy|codex|opencode) norm "$n"; return 0 ;;
    esac
  done
  return 1
}

h=""

# ① 显式覆盖
if [ -n "${DMT_HARNESS:-}" ]; then
  h="$(norm "$DMT_HARNESS")"
  [ -n "$h" ] || { echo "bad DMT_HARNESS: $DMT_HARNESS（want pi|codebuddy|claude|codex|opencode）" >&2; exit 2; }
  note "源=$DMT_HARNESS（显式覆盖）"; printf '%s\n' "$h"; exit 0
fi

# ② herdr 前台进程 argv
argv=""
if [ -n "${DMT_PANE_ARGV+x}" ]; then argv="$DMT_PANE_ARGV"; note "源=DMT_PANE_ARGV（机检逃生舱）"
elif [ -n "$PANE" ]; then argv="$(pane_argv "$PANE")"; note "源=herdr argv（--pane $PANE）"
elif [ -n "${HERDR_ENV:-}" ] && [ -n "${HERDR_PANE_ID:-}" ]; then argv="$(pane_argv "$HERDR_PANE_ID")"; note "源=herdr argv（\$HERDR_PANE_ID=$HERDR_PANE_ID）"
fi
if [ -n "$argv" ]; then
  if h="$(harness_of_cmdline "$argv")" && [ -n "$h" ]; then
    note "argv=$argv ⇒ $h"; printf '%s\n' "$h"; exit 0
  fi
  note "argv=$argv 未命中已知 harness，继续下一判据"
fi

# ③ 环境标记（精确变量；不用 `*_*` 通配，见文件头）
if [ -n "${PI_CODING_AGENT:-}" ]; then h=pi
elif [ "${CLAUDECODE:-}" = "1" ]; then h=claude
elif [ -n "${CODEBUDDY_SETTINGS:-}" ] || [ -n "${CODEBUDDY_CODE_MAX_CONCURRENT_SUBAGENTS:-}" ]; then h=codebuddy
elif [ -n "${CODEX_HOME:-}" ] || [ -n "${CODEX_SANDBOX:-}" ] || [ -n "${CODEX_THREAD_ID:-}" ]; then h=codex
elif [ -n "${OPENCODE:-}" ] || [ -n "${OPENCODE_CONFIG:-}" ] || [ -n "${OPENCODE_CONFIG_CONTENT:-}" ]; then h=opencode
fi
if [ -n "$h" ]; then note "源=环境标记 ⇒ $h"; printf '%s\n' "$h"; exit 0; fi

# ④ 父进程链（$DMT_DETECT_NO_PARENT=1 跳过 —— 仅机检自测要一个稳定 unknown 用例）
pid="${PPID:-}"; i=0
while [ -z "${DMT_DETECT_NO_PARENT:-}" ] && [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ] && [ "$i" -lt 5 ]; do
  cmd="$(ps -o args= -p "$pid" 2>/dev/null | head -1 || true)"
  if [ -n "$cmd" ] && h="$(harness_of_cmdline "$cmd")" && [ -n "$h" ]; then
    note "源=父进程链（pid=$pid，cmd=$cmd）⇒ $h"; printf '%s\n' "$h"; exit 0
  fi
  pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
  i=$((i + 1))
done

# ⑤ 未判定：失败要响亮（不得默认某个 harness）
note "五条判据均未命中"
printf 'unknown\n'
exit 1
