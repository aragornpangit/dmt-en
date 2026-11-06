#!/usr/bin/env bash
# harness-matrix.sh —— 读取 dmt-director/harness_matrix.yaml（单一来源）
#
# 用法：
#   harness-matrix.sh list                        # 列出全部 harness 名（每行一个）
#   harness-matrix.sh get <harness> <field>       # 取某字段（点路径，如 skills.dir_project / slash_prefix / start_cmd / max_subagents_conc）
#   harness-matrix.sh json                        # 输出整份矩阵 JSON（供 jq / 其它脚本消费）
#   harness-matrix.sh install-dirs                # install-skills.sh --harness all 的落点目录（每行一个）
#   harness-matrix.sh install-dirs-for <h1,h2,…>  # 指定 harness 的落点目录（去重，每行一个）
#   harness-matrix.sh doorbell <harness>          # 门铃通道名
#
# 依赖 python3 + PyYAML（矩阵是 YAML）。找不到时 rc=3，调用方应 fail-fast。
# 本脚本是「harness 差异」的唯一读取口：lib-dmt.sh / install-skills.sh / 机检都经它取，
# 不再各写一份 case 分支。
set -eu
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"
MATRIX="${DMT_HARNESS_MATRIX:-$DIR/../harness_matrix.yaml}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "harness-matrix: 需要 python3（读取 harness_matrix.yaml）" >&2; exit 3
fi
if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "harness-matrix: 需要 PyYAML（pip install pyyaml）" >&2; exit 3
fi
[ -f "$MATRIX" ] || { echo "harness-matrix: 矩阵文件不存在：$MATRIX" >&2; exit 3; }

CMD="${1:-}"; shift || true
export DMT_MATRIX_PATH="$MATRIX"

case "$CMD" in
  list)
    python3 - <<'PY'
import os, yaml, sys
m = yaml.safe_load(open(os.environ["DMT_MATRIX_PATH"], encoding="utf-8"))
for h in m.get("harnesses", {}):
    print(h)
PY
    ;;
  get)
    H="${1:?usage: harness-matrix.sh get <harness> <field>}"; F="${2:?missing field}"
    H="$H" F="$F" python3 - <<'PY'
import os, yaml
m = yaml.safe_load(open(os.environ["DMT_MATRIX_PATH"], encoding="utf-8"))
h = os.environ["H"]; f = os.environ["F"]
node = m.get("harnesses", {}).get(h)
if node is None:
    raise SystemExit(f"harness-matrix: 未知 harness: {h}")
for key in f.split("."):
    if not isinstance(node, dict) or key not in node:
        raise SystemExit(f"harness-matrix: {h} 无字段 {f}")
    node = node[key]
if node is None:
    print("")            # null 输出空串（调用方按空判「无/未知」）
elif isinstance(node, bool):
    print("true" if node else "false")
else:
    print(node)
PY
    ;;
  json)
    python3 -c 'import os,yaml,json;print(json.dumps(yaml.safe_load(open(os.environ["DMT_MATRIX_PATH"],encoding="utf-8")),ensure_ascii=False))'
    ;;
  install-dirs)
    python3 - <<'PY'
import os, yaml
m = yaml.safe_load(open(os.environ["DMT_MATRIX_PATH"], encoding="utf-8"))
for d in m.get("install_all_dirs", []):
    print(d)
PY
    ;;
  install-dirs-for)
    HS="${1:?usage: harness-matrix.sh install-dirs-for <h1,h2,…>}"
    DMT_HS="$HS" python3 - <<'PY'
import os, yaml
m = yaml.safe_load(open(os.environ["DMT_MATRIX_PATH"], encoding="utf-8"))
want = [x for x in os.environ["DMT_HS"].replace(" ", "").split(",") if x]
seen = []
for h in want:
    node = m.get("harnesses", {}).get(h)
    if node is None:
        raise SystemExit(f"harness-matrix: 未知 harness: {h}")
    sk = node.get("skills", {})
    for d in (sk.get("dir_project"), sk.get("dir_project_extra")):
        if d and d not in seen:
            seen.append(d)
for d in seen:
    print(d)
PY
    ;;
  doorbell)
    H="${1:?usage: harness-matrix.sh doorbell <harness>}"
    H="$H" python3 - <<'PY'
import os, yaml
m = yaml.safe_load(open(os.environ["DMT_MATRIX_PATH"], encoding="utf-8"))
n = m.get("harnesses", {}).get(os.environ["H"])
if n is None: raise SystemExit("harness-matrix: 未知 harness")
print(n.get("doorbell", os.environ["H"]))
PY
    ;;
  *)
    echo "usage: harness-matrix.sh {list|get <h> <field>|json|install-dirs|install-dirs-for <h,…>|doorbell <h>}" >&2
    exit 2
    ;;
esac
