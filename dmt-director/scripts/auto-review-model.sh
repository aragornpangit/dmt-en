#!/usr/bin/env bash
# auto-review-model.sh —— cbc auto 模式复核器（autoModeClassifier）模型健康门
#
# 背景（读 codebuddy.js 二进制语义所得，非猜测）：
#   auto 模式下每个**需审批**的工具调用都要过一次自动复核。为避免企业网关 500/429 限流
#   把正常命令拖成 no verdict，我们把复核模型钉到本地 sglang 端点。但 cbc 的语义是：
#   **一旦在 `subagents.agents.autoModeClassifier.model` 钉了模型，
#   `resolveAutoReviewModels()` 就 early-return，不再生成内置 fallback 链**
#   （内置链 `{reviewer: deepseek-flash(strict), fallback: shippedDefault}` 只在「不钉」时才出现）。
#   于是本地端点不可达时，复核没有任何退路 ⇒ 直接 no verdict ⇒ 命令被判失败。
#
# 做法：harness 启动前探活本地端点 ——
#   可达   ⇒ 把该键钉到本地模型（走本地、避开网关）
#   不可达 ⇒ **删除该键**，回退 cbc 内置链路（网关模型，即「cbc 能用的模型」）
#
# 用法：bash auto-review-model.sh [--check] [--url URL] [--timeout SEC]
#        [--settings PATH] [--local-model ID] [--quiet] [--off]
#   环境变量：DMT_LOCAL_MODEL_HOST / DMT_LOCAL_MODEL_PORT（拼端点 URL；.env 可配，见 <.env.example>）
#             DMT_AUTO_REVIEW_URL 可直接给整条 URL（覆盖 host/port 拼装）
#             DMT_AUTO_REVIEW_LOCAL_MODEL / CODEBUDDY_SETTINGS
#             DMT_AUTO_REVIEW_GATE=off  等价于 --off
#   --check  只报告、不写盘
#   --quiet  只在「有变化」时输出一行
#   --off    整门关闭：不探活、不改设置（保留人工选择；留给「就是要纯走网关」的逃生舱）
# 退出码恒为 0（绝不阻断 harness 启动）。幂等：值未变则不写盘。
set -u

# 载入 .env（DMT_LOCAL_MODEL_HOST / DMT_LOCAL_MODEL_PORT 等；已导出的环境变量优先）
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$DIR/lib-dmt.sh"
dmt_load_env

URL="${DMT_AUTO_REVIEW_URL:-http://${DMT_LOCAL_MODEL_HOST:-localhost}:${DMT_LOCAL_MODEL_PORT:-30000}/v1/models}"
LOCAL_MODEL="${DMT_AUTO_REVIEW_LOCAL_MODEL:-custom-local:Qwen3.8-27b}"
SETTINGS="${CODEBUDDY_SETTINGS:-$HOME/.codebuddy/settings.json}"
TIMEOUT=2
CHECK=0
QUIET=0
OFF=0
case "${DMT_AUTO_REVIEW_GATE:-}" in off|0|false|no) OFF=1 ;; esac

while [ $# -gt 0 ]; do
  case "$1" in
    --check)       CHECK=1 ;;
    --quiet)       QUIET=1 ;;
    --off)         OFF=1 ;;
    --url)         URL="${2:?--url needs a value}"; shift ;;
    --timeout)     TIMEOUT="${2:?--timeout needs a value}"; shift ;;
    --settings)    SETTINGS="${2:?--settings needs a value}"; shift ;;
    --local-model) LOCAL_MODEL="${2:?--local-model needs a value}"; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# --quiet：只在「有变化 / 异常」时输出；常规叙述静默。（历史上本函数把变化行也一并吞掉，
# 与「--quiet 只在有变化时输出一行」的文档不符 —— 2026-11-03 修正。）
say_change() { echo "$@"; }
say()        { [ "$QUIET" = 1 ] || echo "$@"; }

if [ "$OFF" = 1 ]; then
  say_change "[auto-review-model] 健康门已关闭（--off / DMT_AUTO_REVIEW_GATE=off）⇒ 不动设置"
  exit 0
fi

# ---- 探活本地端点 ----
up=0
if command -v curl >/dev/null 2>&1; then
  code="$(curl -s -o /dev/null -m "$TIMEOUT" -w '%{http_code}' "$URL" 2>/dev/null)" || code=000
  [ -z "$code" ] && code=000
  [ "$code" = "200" ] && up=1
  probe="HTTP $code"
else
  probe="no curl"
  say_change "[auto-review-model] 警告：本机无 curl，无法探活 ⇒ 按不可达处理（可用性优先）"
fi

# ---- 决策 ----
if [ "$up" = 1 ]; then
  MODE=pin; WANT="$LOCAL_MODEL"; PLAN="复核器钉本地：$LOCAL_MODEL"
else
  MODE=unpin; WANT=""; PLAN="本地端点不可达（$probe）⇒ 摘钉，回退 cbc 内置链路（网关模型）"
fi

if [ "$CHECK" = 1 ]; then
  echo "[auto-review-model] 探活 $URL → $probe；$PLAN（--check，未写盘）"
  exit 0
fi

# ---- 落盘（python3 原子写 + 保留文件权限）----
if ! command -v python3 >/dev/null 2>&1; then
  say_change "[auto-review-model] 警告：无 python3，无法改写 settings ⇒ 保持现状（$PLAN 未生效）"
  exit 0
fi

out="$(python3 - "$SETTINGS" "$MODE" "$WANT" <<'PY' 2>&1
import json, os, sys

path, mode, model = sys.argv[1], sys.argv[2], sys.argv[3]

def load():
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}
    except Exception as e:
        print("ERR bad-json %s" % e)
        sys.exit(3)

d = load() or {}
if not isinstance(d, dict):
    print("ERR not-an-object")
    sys.exit(3)

agents = d.setdefault("subagents", {}).setdefault("agents", {})
agent = agents.setdefault("autoModeClassifier", {})
if not isinstance(agent, dict):
    print("ERR agent-not-an-object")
    sys.exit(3)

if mode == "pin":
    if agent.get("model") == model:
        print("noop")
        sys.exit(0)
    agent["model"] = model
    action = "pinned->%s" % model
else:
    if "model" not in agent:
        print("noop")
        sys.exit(0)
    del agent["model"]
    action = "unpinned"
    # 清理空壳，避免留下 {} 噪声
    if not agent:
        agents.pop("autoModeClassifier", None)
    if not agents:
        d["subagents"].pop("agents", None)
    if not d["subagents"]:
        d.pop("subagents", None)

try:
    st = os.stat(path)
    mode_bits = st.st_mode & 0o777
except FileNotFoundError:
    mode_bits = 0o600

tmp = "%s.tmp.%d" % (path, os.getpid())
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.chmod(tmp, mode_bits)
os.replace(tmp, path)
print(action)
PY
)"

case "$out" in
  noop)
    say "[auto-review-model] 无变化（$PLAN）" ;;
  pinned-*|unpinned)
    say_change "[auto-review-model] $out · settings=$SETTINGS · $PLAN" ;;
  *)
    say_change "[auto-review-model] 改写失败：$out（保持原设置）" ;;
esac
exit 0
