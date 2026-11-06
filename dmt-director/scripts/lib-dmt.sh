#!/usr/bin/env bash
# dmt 脚本公共库：工作树根 / 角色解析 / pane 查询。被各脚本 source，不单独执行。
# 用法：DIR="$(cd -P "$(dirname "$0")" && pwd -P)"; . "$DIR/lib-dmt.sh"
# 目的：同一判据只有一份实现 —— 复制粘贴出来的副本已经分叉过（dry-run 守卫、fail-closed 修复各漏一处）。

# 本库所在目录（source 时解析一次；用于拼「同目录脚本」的绝对路径，免受调用方后续 cd 影响）
DMT_SCRIPTS_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# 载入 .env（内网端点等环境私有配置；不覆盖已存在的环境变量）
# 查找顺序：$DMT_ENV_FILE → <项目根>/.env → <技能仓根>/.env
dmt_load_env() {
  local f="${DMT_ENV_FILE:-}"
  if [ -z "$f" ]; then
    local root; root="$(dmt_root 2>/dev/null || true)"
    for cand in "$root/.env" "$DMT_SCRIPTS_DIR/../../.env"; do
      [ -n "$cand" ] && [ -f "$cand" ] && { f="$cand"; break; }
    done
  fi
  [ -n "$f" ] && [ -f "$f" ] || return 0
  # 只用 KEY=VALUE 行；已导出的环境变量优先（.env 不覆盖）
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|\#*) continue ;; esac
    case "$line" in *=*) ;; *) continue ;; esac
    local k="${line%%=*}" v="${line#*=}"
    case "$k" in [A-Za-z_][A-Za-z0-9_]*) ;; *) continue ;; esac
    # 去掉值两端可能的引号
    case "$v" in \"*\") v="${v#\"}"; v="${v%\"}" ;; \'*\') v="${v#\'}"; v="${v%\'}" ;; esac
    if [ -z "${!k:-}" ]; then export "$k=$v"; fi
  done < "$f"
}

# 主工作树根：git common dir 的父目录（在 worktree 里跑也指回主树）；非 git 目录回退当前目录
dmt_root() {
  local r
  r="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "$r" ]; then
    case "$r" in */.git) r="${r%/.git}" ;; esac
    printf '%s' "$r"
  else
    git rev-parse --show-toplevel 2>/dev/null || pwd
  fi
}

# 角色解析：参数（空或 "-"）⇒ $DMT_ROLE ⇒ $DMT_PANE_ROLE ⇒ herdr pane label
dmt_role() {
  local r="${1:-}" pane
  case "$r" in ""|-) r="${DMT_ROLE:-}" ;; esac
  if [ -z "$r" ] && [ -n "${DMT_PANE_ROLE:-}" ]; then r="$DMT_PANE_ROLE"; fi
  if [ -z "$r" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
    pane="$(dmt_herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" 2>/dev/null \
      | jq -r --arg p "$HERDR_PANE_ID" '.result.panes[]? | select(.pane_id==$p) | .label' 2>/dev/null | head -1 || true)"
    r="$pane"
  fi
  printf '%s' "$r"
}

# herdr 查询统一入口。$DMT_HERDR_SOCKET_PATH 可显式指定当前 workspace 的 socket；
# 其余情况沿用 herdr 的 session 发现。
dmt_herdr() {
  if [ -n "${DMT_HERDR_SOCKET_PATH:-}" ]; then
    HERDR_SOCKET_PATH="$DMT_HERDR_SOCKET_PATH" HERDR_ENV=1 herdr "$@" 2>/dev/null
  else
    HERDR_ENV=1 herdr "$@" 2>/dev/null
  fi
}

# 修正本进程的 herdr 环境（2026-11-06 第八十三次，codex 实证）。
#
# 为什么必须单独一个函数：`pane="$(dmt_pane_by_label …)"` 是**子 shell**，函数内的 export
# 传不回父进程 ⇒ 会出现「查到了 pane、发送却仍走陈旧 socket」（实测：codex 第三级查到
# w9:p1 后，随后 herdr agent prompt 仍报 bcr-nihui server_not_running）。
# ⇒ 需要修正时，必须在**父 shell**里先调本函数，再调 dmt_pane_by_label。
#
# 判据（都不猜）：当前 $HERDR_SOCKET_PATH 连得上且该 workspace 有 pane ⇒ 不动；
# 否则遍历 $HOME/.config/herdr/sessions/*/herdr.sock，取「含目标 label 且 cwd==$PWD」的唯一命中。
dmt_herdr_env_fix() {
  local want="${1:-}" sock sess hit cnt pwd_real
  if [ -n "${HERDR_SOCKET_PATH:-}" ] && [ -S "${HERDR_SOCKET_PATH:-}" ]; then
    if dmt_herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" 2>/dev/null | jq -e '(.result.panes // []) | length > 0' >/dev/null 2>&1; then
      return 0
    fi
  fi
  pwd_real="$(pwd -P 2>/dev/null || pwd)"
  for sock in "$HOME"/.config/herdr/sessions/*/herdr.sock; do
    [ -S "$sock" ] || continue
    sess="$(basename "$(dirname "$sock")")"
    if [ -n "$want" ]; then
      hit="$(HERDR_SESSION="$sess" HERDR_SOCKET_PATH="$sock" HERDR_ENV=1 herdr pane list 2>/dev/null \
        | jq -r --arg l "$want" --arg c "$pwd_real" \
            '.result.panes[]? | select(.label==$l and ((.cwd // "")|sub("/$";""))==$c) | .pane_id' 2>/dev/null || true)"
      cnt="$(printf '%s\n' "$hit" | sed '/^$/d' | wc -l | tr -d ' ')"
      if [ "$cnt" != "1" ]; then continue; fi
    fi
    export DMT_HERDR_SOCKET_PATH="$sock"
    export HERDR_SOCKET_PATH="$sock"
    export HERDR_SESSION="$sess"
    return 0
  done
  return 1
}

# pane label -> pane id（不存在给空；herdr 不可用也给空）
#
# 匹配顺序（2026-11-05 第八十一次：多 harness 同 workspace 场景）：
#   ① 精确 label == <角色名>（契约默认写法）
#   ② 否则按「<角色名>-*」前缀回退（如 director-pi / devm-pi；多套团队同 workspace 时用）
#     回退**必须唯一**：命中多个 ⇒ 给空（不猜，调用方按「label 不符 ⇒ 停下问用户」处置）
dmt_pane_by_label() {
  local want="$1" out id hits n
  out="$(dmt_herdr pane list --workspace "${HERDR_WORKSPACE_ID:-}" 2>/dev/null || true)"
  id="$(printf '%s' "$out" | jq -r --arg l "$want" '.result.panes[]? | select(.label==$l) | .pane_id' 2>/dev/null | head -1 || true)"
  [ -n "$id" ] && { printf '%s' "$id"; return 0; }
  hits="$(printf '%s' "$out" | jq -r --arg p "${want}-" '.result.panes[]? | select((.label // "") | startswith($p)) | .pane_id' 2>/dev/null || true)"
  n="$(printf '%s\n' "$hits" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [ "$n" = "1" ]; then
    printf '%s' "$(printf '%s\n' "$hits" | sed '/^$/d' | head -1)"
    return 0
  fi

  # ③ 跨 session 回退（2026-11-06 第八十三次，codex 实测）：某些 harness（codex）的 shell 工具
  #    复用**常驻 shell 的旧环境**，$HERDR_SOCKET_PATH / $HERDR_WORKSPACE_ID 指向已废弃的 session
  #    ⇒ 上面两级必空。此时遍历 $HOME/.config/herdr/sessions/*/herdr.sock，
  #    按 **当前目录 ＋ 目标 label** 找唯一命中（不猜：多命中一律给空）。
  local pwd_real sock hit cnt
  pwd_real="$(pwd -P 2>/dev/null || pwd)"
  for sock in "$HOME"/.config/herdr/sessions/*/herdr.sock; do
    [ -S "$sock" ] || continue
    hit="$(HERDR_SOCKET_PATH="$sock" HERDR_ENV=1 herdr pane list 2>/dev/null \
      | jq -r --arg l "$want" --arg c "$pwd_real" \
          '.result.panes[]? | select(.label==$l and ((.cwd // "")|sub("/$";""))==$c) | .pane_id' 2>/dev/null || true)"
    cnt="$(printf '%s\n' "$hit" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [ "$cnt" = "1" ]; then
      local sess; sess="$(basename "$(dirname "$sock")")"
      # 命中即**修正本进程的 herdr 环境**：否则「查到了 pane、发送却仍走陈旧 socket」
      # （2026-11-06 实测：codex 里第三级查到 w9:p1 后，herdr agent prompt 仍报 bcr-nihui server_not_running）。
      export DMT_HERDR_SOCKET_PATH="$sock"
      export HERDR_SOCKET_PATH="$sock"
      export HERDR_SESSION="$sess"
      printf '%s' "$(printf '%s\n' "$hit" | sed '/^$/d' | head -1)"
      return 0
    fi
  done
  return 0
}

# pane 的 agent_status（unknown = 该 pane 没有 agent 在跑）
dmt_pane_status() {
  dmt_herdr pane get "$1" 2>/dev/null \
    | jq -r '.result.pane.agent_status // "unknown"' 2>/dev/null || echo unknown
}

# pane 里前台进程的 argv（空格连接；拿不到给空）
# $DMT_PANE_ARGV 可整体覆盖 —— 仅供机检自测判据（与 $DMT_HARNESS_CMD 同思路的逃生舱）。
dmt_pane_argv() {
  if [ -n "${DMT_PANE_ARGV+x}" ]; then printf '%s' "${DMT_PANE_ARGV}"; return 0; fi
  dmt_herdr pane process-info --pane "$1" 2>/dev/null \
    | jq -r '.result.process_info.foreground_processes[0].argv // [] | join(" ")' 2>/dev/null || true
}

# 该 pane 的前台 harness 是否跑在「自动批准」档位（2026-11-03 第六十三次立规）。
#
# 为什么需要它：dmt 全靠 pane 自主跑长任务，一旦 pane 落在 default/manual 档，每次工具调用都撞审批 ——
# 现象是「脚本超时 / 命令失败」（2026-11-03 bcr-nh 实测：33 次工具栏 ASK，脚本本体 57ms 正常，
# 另一 pane 标题直接写着 file-claim.sh 审批超时）。不查档位就查不到根因。
#
# 判据一律读 **argv**，不信屏幕文字：
#   屏幕上的 "auto mode on" 只在手动会话首屏出现，之后被输出顶走；而 argv 是恒定事实。
# 各 harness 的自动档参数（与 dmt_harness_cmd 同源）：
#   codebuddy  --permission-mode auto      （另有 -y/--dangerously-skip-permissions）
#   claude     --permission-mode auto      （另有 --dangerously-skip-permissions）
#   codex      -a never / --ask-for-approval never / --yolo（-y 在 codex 里不是批准开关）
#   opencode   --auto / --dangerously-skip-permissions
#   pi         --approve
# 返回：0 = 自动档；1 = 非自动档；2 = 拿不到 argv（无法判定，调用方决定是告警还是放过）
dmt_pane_auto_mode() {
  local pane="$1" argv tok prev=""
  argv="$(dmt_pane_argv "$pane")"
  [ -n "$argv" ] || return 2
  # 逐 token 判，不用 `*"--auto"*` 这种子串匹配 —— 那会把 `--autocompact` 之类误判成自动档。
  for tok in $argv; do
    case "$tok" in
      --permission-mode=auto|--dangerously-skip-permissions|--yolo|--approve) return 0 ;;
      --auto|--dangerously-bypass-approvals-and-sandbox) return 0 ;;
      --ask-for-approval=never) return 0 ;;
      auto) [ "$prev" = "--permission-mode" ] && return 0 ;;
      never) [ "$prev" = "-a" ] || [ "$prev" = "--ask-for-approval" ] && return 0 ;;
    esac
    prev="$tok"
  done
  return 1
}

# 就绪判据：轮询 agent_status 不再是 unknown。
# 不要用 wait-output 匹配屏幕文字 —— 对已在跑的 pane 它会立刻命中历史输出，等于没有判据。
dmt_wait_ready() {
  local pane="$1" limit="${2:-60}" i=0 st
  while [ "$i" -lt "$limit" ]; do
    st="$(dmt_pane_status "$pane")"
    if [ "$st" != "unknown" ]; then echo "ready ($st): $pane"; return 0; fi
    sleep 1; i=$((i + 1))
  done
  echo "WARN: $pane still unknown after ${limit}s" >&2
  return 1
}

# 启动回执：pane 输出必须同时含角色名与一次性凭据，才证明角色技能确实已加载。
# rc=2 表示参数/凭据缺失；rc=1 表示超时。
dmt_confirm_role_ready() {
  local pane="$1" role="$2" token="$3" limit="${4:-60}" i=0 text=""
  [ -n "$pane" ] && [ -n "$role" ] && [ -n "$token" ] || return 2
  while [ "$i" -lt "$limit" ]; do
    text="$(dmt_herdr pane read "$pane" --source recent-unwrapped --lines 240 2>/dev/null || true)"
    if printf '%s' "$text" | grep -qF -- "$role" &&
       printf '%s' "$text" | grep -qF -- "$token"; then
      return 0
    fi
    sleep 1; i=$((i + 1))
  done
  return 1
}

# 生成角色启动说明。技能按 harness 限定名给出，避免 Codex 插件技能短名静默不展开。
dmt_skill_prompt() {
  local h="${1:-codebuddy}" name="${2:?dmt_skill_prompt <harness> <skill-name>}" extra="${3:-}"
  local label="${4:-$name}" ref tree_mode
  ref="$(dmt_skill_ref "$h" "$name")"
  tree_mode="$(dmt_tool_mode "$h")"
  if [ "$h" = "codex" ] && [ "$tree_mode" = "herdr" ]; then
    printf '请立即使用技能 `%s`（%s）。Codex 默认无子代理编排工具；若当前有 spawn_agent / send_message / wait_agent，只能在本 pane 现有人员架构内使用。不得用 exec 启动 codex exec 子进程。完全读取并执行技能；角色为 `%s`。%s' \
      "$ref" "$name" "$label" "$extra"
    return 0
  fi
  printf '请立即使用技能 `%s`（%s）。完全读取并执行该技能；角色为 `%s`。%s' \
    "$ref" "$name" "$label" "$extra"
}

# 某技能在当前 harness 的注册名；DMT 自身技能不加插件前缀。
dmt_skill_ref() {
  local h="${1:-codebuddy}" name="${2:?dmt_skill_ref <harness> <skill-name>}" prefix
  if [ "$h" = "codex" ]; then
    skill_policy_ref "$name" || return 1
    return 0
  fi
  prefix="$(dmt_harness_field "$h" skill_prefix)"
  if [ -n "$prefix" ]; then printf '%s%s' "$prefix" "$name"; else printf '%s' "$name"; fi
}

# Codex 的注册名取决于当前会话 catalog：配置里有独立条目时是裸名，只有插件时是
# mattpocock-skills:<name>。解析失败回退插件限定名，避免静默变成普通提问。
skill_policy_ref() {
  local name="$1" prefix standalone
  case "$name" in
    dmt-*) printf '%s' "$name"; return 0 ;;
  esac
standalone="$(DMT_SKILL_NAME="$name" python3 - "${CODEX_HOME:-$HOME/.codex}/config.toml" <<'PY' 2>/dev/null || true
import os, sys, tomllib
try:
    path = sys.argv[1]
    c = tomllib.load(open(path, "rb"))
except Exception:
    c = {}
name = os.environ["DMT_SKILL_NAME"]
skills = c.get("skills", {})
enabled = skills.get("enabled", True) if isinstance(skills, dict) else True
for entry in skills.get("config", []) if isinstance(skills, dict) else []:
    if isinstance(entry, dict) and f"/skills/{name}/SKILL.md" in str(entry.get("path", "")):
        enabled = entry.get("enabled", True)
        break
try:
    text = open(path, encoding="utf-8", errors="ignore").read()
except Exception:
    text = ""
if enabled and f"/skills/{name}/SKILL.md" in text:
    print("standalone")
PY
)"
  if [ -n "$standalone" ]; then
    printf '%s' "$name"
    return 0
  fi
  prefix="$(dmt_harness_field codex skill_prefix)"
  if [ -n "$prefix" ]; then printf '%s%s' "$prefix" "$name"; else printf '%s' "$name"; fi
}

# 启动器是否支持首轮 prompt；true 时技能与任务必须随启动一次下发。
dmt_start_has_first_prompt() {
  [ "$(dmt_harness_field "$1" first_prompt)" = "true" ]
}

# helper 开法判据（2026-11-04 第七十五次，可观测）：本体在忙 且 有待办积压。
#   ① 本体 pane agent_status == working（busy）
#   ② 该角色有 ≥1 条待办超过 $2 分钟未处理（默认 10）：
#        未读 inbox/<role>/*.md（mtime 早于 N 分钟）或 .doing/ 有在办文件
# 两条都成立 ⇒ rc=0（可开 helper）；否则 rc=1。
# 这是唯一判据：旧口径「忙不过来 / 回报积压 / 仍有待办 三条同时成立」无观测手段，已废。
dmt_helper_eligible() {
  local role="$1" mins="${2:-10}" pane st root inbox nm now
  pane="$(dmt_pane_by_label "$role")"
  [ -n "$pane" ] || return 1
  st="$(dmt_pane_status "$pane")"
  [ "$st" = "working" ] || return 1
  root="$(dmt_root)"; inbox="$root/inbox/$role"
  [ -d "$inbox" ] || return 1
  # 未读：mtime 早于 N 分钟
  nm="$(find "$inbox" -maxdepth 1 -name '*.md' -mmin "+$mins" -print -quit 2>/dev/null || true)"
  [ -n "$nm" ] && return 0
  # 在办：.doing/ 非空即算积压
  if [ -d "$inbox/.doing" ] && [ -n "$(find "$inbox/.doing" -maxdepth 1 -name '*.md' -print -quit 2>/dev/null)" ]; then
    return 0
  fi
  return 1
}

# harness 白名单与启动命令（默认 codebuddy；备选 pi / opencode / codex / claude）。
# 2026-11-03 第六十二次：补齐 claude（Claude Code），并把「技能如何被调起」抽成 dmt_skill_cmd ——
# 五个 harness 的技能发现目录与斜杠写法并不一致，写死一种会在别的 harness 上静默失效。
# 解析优先级：显式参数 ⇒ $DMT_HARNESS ⇒ codebuddy。非法值 rc=2（错误写 stderr，便于调用方 fail-fast）。
dmt_harness_name() {
  local h="${1:-}"
  case "$h" in ""|-) h="${DMT_HARNESS:-codebuddy}" ;; esac
  case "$h" in
    codebuddy|pi|opencode|codex|claude) printf '%s' "$h" ;;
    # 常见别名（herdr 侧 agent 名为 claude，别名 claude-code）
    claudecode|claude-code) printf '%s' 'claude' ;;
    *) echo "bad harness: $h (want codebuddy|pi|opencode|codex|claude)" >&2; return 2 ;;
  esac
}

# 技能调用命令：按 harness 生成「往 pane 里输入的那一行」。
# 前缀**不在这里写死**：由 harness_matrix.yaml 的 slash_prefix 提供（单一来源）。
#   · claude / codebuddy / codex / opencode ⇒ `/dmt-dm`
#   · pi                                   ⇒ `/skill:dmt-dm`
# `pi -p /dmt-dm` 不展开；`pi -p /skill:dmt-dm` 正常展开 —— 写错前缀会静默变成普通提问。
dmt_skill_cmd() {
  local h="${1:-codebuddy}" name="${2:?dmt_skill_cmd <harness> <skill-name>}"
  local prefix
  prefix="$(dmt_harness_field "$h" slash_prefix)"
  [ -n "$prefix" ] || prefix="/"   # 矩阵不可用时回退（pi 以外全部是 /）
  printf '%s%s' "$prefix" "$name"
}

# 从 harness_matrix.yaml 取字段（经 harness-matrix.sh）；矩阵/依赖不可用时给空、返回非 0。
dmt_harness_field() {
  local h="$1" f="$2"
  [ -x "$DMT_SCRIPTS_DIR/harness-matrix.sh" ] || return 1
  bash "$DMT_SCRIPTS_DIR/harness-matrix.sh" get "$h" "$f" 2>/dev/null
}

# 该 harness 的并发 subagent 上限（harness 侧能力；空＝未知/不设）。
#   runtime_override 可按当前用户的配置覆盖矩阵静态默认值：codex 的
#   [agents].max_concurrent_threads_per_session 才是实际会话上限。
dmt_harness_max_conc() {
  local h="$1" n cfg path val
  n="$(dmt_harness_field "$h" max_subagents_conc)"
  cfg="$(dmt_harness_field "$h" max_subagents_config)"
  if [ "$cfg" = "agents.max_concurrent_threads_per_session" ]; then
    path="${CODEX_HOME:-$HOME/.codex}/config.toml"
    if [ -f "$path" ]; then
      val="$(DMT_CODEX_CONFIG="$path" python3 - 2>/dev/null <<'PY'
import os, tomllib
try:
    c = tomllib.load(open(os.environ["DMT_CODEX_CONFIG"], "rb"))
    print(c.get("agents", {}).get("max_concurrent_threads_per_session", ""))
except Exception:
    pass
PY
)"
      [ -n "$val" ] && n="$val"
    fi
  fi
  printf '%s' "$n"
}

# 并发上限对应的环境变量名（空＝无）。
dmt_harness_max_env() {
  dmt_harness_field "$1" max_subagents_env
}

# 并发上限的可读描述（供回报 / 文档引用；不改行为）：
#   harness 有 max_subagents_conc ⇒ "上限 N（env: VAR）"，否则 "未声明上限"。
dmt_concurrency_cap() {
  local h="$1" n e
  n="$(dmt_harness_max_conc "$h")"
  e="$(dmt_harness_max_env "$h")"
  if [ -n "$n" ]; then
    if [ -n "$e" ]; then printf '上限 %s（env: %s）' "$n" "$e"; else printf '上限 %s' "$n"; fi
  else
    printf '未声明上限'
  fi
}

# harness 启动命令。$DMT_HARNESS_CMD 可整体覆盖（逃生舱：任意 harness / 额外参数）。
# codebuddy 分支在启动前做两件事（机队所有 pane 共用这一处实现）：
#   ① `auto-review-model.sh` 健康门 —— 探活本地复核端点：可达 ⇒ 复核器钉本地（避开企业网关限流）；
#      不可达 ⇒ 摘钉、回退 cbc 内置链路（网关模型）。**钉了模型会禁用 cbc 内置 fallback**
#      （二进制 `resolveAutoReviewModels()` 一钉即 early-return），所以才需要这道门（详见脚本头注释）。
#   ② 前置 `CODEBUDDY_AUTO_REVIEW_TIMEOUT_MS=300000` —— auto 模式下每个需审批的工具调用都要过一次
#      复核器（默认 90s 硬上限，含整段会话上下文），企业网关抖动/429 时极易 no verdict ⇒ 整条命令被判失败。
#      用户级 settings.json 的 `env` 块同键兜底（覆盖手动启动的会话），两条路都留，任一失效仍生效。
dmt_harness_cmd() {
  local h="${1:-codebuddy}"
  if [ -n "${DMT_HARNESS_CMD:-}" ]; then printf '%s' "$DMT_HARNESS_CMD"; return 0; fi
  # 启动命令来自 harness_matrix.yaml（单一来源）；codebuddy 的 start_cmd 里内嵌
  # auto-review 健康门与超时预算（矩阵中的 start_cmd 字符串引用 $DMT_SCRIPTS_DIR，
  # 在**这里**展开，因此矩阵不必知道脚本目录的绝对路径）。
  local cmd
  cmd="$(dmt_harness_field "$h" start_cmd)" || { echo "bad harness: $h" >&2; return 2; }
  [ -n "$cmd" ] || { echo "bad harness: $h" >&2; return 2; }
  # 展开 $DMT_SCRIPTS_DIR（矩阵里以字面量存放，避免把机器相关绝对路径写进受版本控制的 YAML）
  printf '%s' "${cmd//\$DMT_SCRIPTS_DIR/$DMT_SCRIPTS_DIR}"
}

# codex 在 herdr 中若无原生子代理接口，直接内联为单进程 harness；
# 其它容器模式仍走账号配置，不改变普通用户选择。
dmt_tool_mode() {
  local h="$1" mode
  mode="$(dmt_harness_field "$h" tree_mode)"
  [ -n "$mode" ] || mode='full'
  printf '%s' "$mode"
}
