#!/usr/bin/env bash
# check-dmt.sh —— dmt 合并机检入口（P5：结构断言 + 内容断言，一处运行）
#
# 数据来源（单一来源）：
#   · dmt-director/dmt_contract.yaml  —— 结构事实 + content_assertions（内容断言表）
#   · dmt-director/harness_matrix.yaml —— harness 矩阵
#   · team.md / team/*.md / OPS.md / ops/*.md / 各 SKILL.md —— 被检查对象
#
# 用法：bash check-dmt.sh [项目根目录]
#   环境变量：DMT_SKILLS_DIR（技能目录；默认 <root>/.agents/skills，
#             维护本仓时默认 <repo>，因为技能正本在各角色目录）
#             DMT_CONTRACT_YAML（结构契约）
#
# 退出码：0=ALL_PASS；1=HAS_FAIL；2=用法错；3=缺依赖。
set -u

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO="$(cd -P "$SCRIPT_DIR/../.." && pwd -P)"
ROOT="$(cd -P "${1:-$PWD}" && pwd -P)" || exit 2
if [ -n "${DMT_SKILLS_DIR:-}" ]; then
  SKILLS_DIR="$DMT_SKILLS_DIR"
elif [ "$ROOT" = "$REPO" ]; then
  SKILLS_DIR="$REPO"
else
  SKILLS_DIR="$ROOT/.agents/skills"
fi
CONTRACT_YAML="${DMT_CONTRACT_YAML:-$REPO/dmt-director/dmt_contract.yaml}"
export DMT_CONTRACT_YAML="$CONTRACT_YAML"
export DMT_IS_REPO=0
[ "$ROOT" = "$REPO" ] && export DMT_IS_REPO=1

if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "FAIL 需要 python3 + PyYAML"; exit 3
fi
[ -f "$CONTRACT_YAML" ] || { echo "FAIL 结构契约不存在：$CONTRACT_YAML"; exit 2; }

fail=0
ok()  { echo "OK   $*"; }
bad() { echo "FAIL $*"; fail=1; }

# 契约 / OPS 定位：目标项目里 docs/team.md（软链）；仓内维护时用正本目录。
if [ -f "$ROOT/docs/team.md" ]; then
  DOCS_DIR="$ROOT/docs"
elif [ "$ROOT" = "$REPO" ]; then
  DOCS_DIR="$REPO/dmt-director"   # 维护仓：team.md 在 dmt-director/ 下
else
  DOCS_DIR="$ROOT/docs"
fi

echo "项目根：    $ROOT"
echo "技能目录：  $SKILLS_DIR"
echo "docs 目录： $DOCS_DIR"
echo "结构契约：  $CONTRACT_YAML"
echo

# ---------- A. 结构断言（原 check-dmt-structure.sh） ----------
echo "===== A. 结构断言 ====="

echo "== A1) 版本同号（dmt_contract.yaml.version = 全部 version_sources） =="
ver="$(python3 -c 'import os,yaml;print(yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["version"])')"
echo "契约版本：$ver"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  path="$REPO/$f"
  if [ ! -f "$path" ]; then
    sk="$(basename "$(dirname "$f")")"; path="$SKILLS_DIR/$sk/SKILL.md"
  fi
  [ -f "$path" ] || { bad "版本源缺失：$f"; continue; }
  case "$f" in
    dmt-director/team.md) tp="$path"; [ -f "$tp" ] || tp="$DOCS_DIR/team.md"; got="$(head -5 "$tp" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" ;;
    *) got="$(sed -n 's/^version: *//p' "$path" | head -1)" ;;
  esac
  if [ "$got" = "$ver" ]; then ok "版本同号 $f ($got)"; else bad "版本不同号 $f：$got ≠ $ver"; fi
done < <(python3 -c 'import os,yaml;[print(x) for x in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["version_sources"]]')

echo
echo "== A2) 技能清单（七个技能各就各位，frontmatter name 一致） =="
while IFS= read -r skill; do
  skill="${skill% }"; [ -n "$skill" ] || continue
  f="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$f" ]; then bad "技能缺失 $skill（$f）"; continue; fi
  nm="$(sed -n 's/^name: *//p' "$f" | head -1)"
  if [ "$nm" = "$skill" ]; then ok "技能 $skill（name 一致）"; else bad "技能 $skill：frontmatter name=$nm"; fi
done < <(python3 -c 'import os,yaml;[print(k) for k in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["skills"]]')

echo
echo "== A3) 产物目录 / 运行时目录 =="
if [ "$ROOT" = "$REPO" ]; then
  echo "SKIP 维护仓自身 —— 不要求装产物目录"
else
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    if [ -d "$ROOT/$d" ]; then ok "目录 $d"; else bad "目录缺失 $d"; fi
  done < <(python3 -c 'import os,yaml;[print(x) for x in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["artifact_dirs"]]')
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    if [ -d "$ROOT/$d" ]; then ok "运行时目录 $d"; else bad "运行时目录缺失 $d"; fi
  done < <(python3 -c 'import os,yaml;[print(x) for x in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["runtime_dirs"]]')
fi

echo
echo "== A3b) 操作手册任务拆分与技能预算 =="
if [ "$ROOT" = "$REPO" ]; then
  OPS_SRC="$REPO/dmt-director/ops"
else
  OPS_SRC="$ROOT/dmt-director/ops"
fi
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ -f "$OPS_SRC/$f" ]; then ok "操作手册 $f"; else bad "操作手册缺失 $f"; fi
done < <(python3 -c 'import os,yaml;[print(x) for x in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8")).get("ops_docs",[])]')
while IFS=$'\t' read -r skill budget; do
  [ -n "$skill" ] || continue
  f="$SKILLS_DIR/$skill/SKILL.md"
  [ -f "$f" ] || continue
  size="$(wc -c < "$f")"
  if [ "$size" -le "$budget" ]; then ok "技能预算 $skill ($size <= $budget B)"; else bad "技能超预算 $skill ($size > $budget B)"; fi
done < <(python3 -c 'import os,yaml;[print(k+"\t"+str(v)) for k,v in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8")).get("skill_budgets",{}).items()]')

echo
echo "== A4) 脚本齐备且可执行 + 已废止脚本不得回潮 =="
while IFS= read -r s; do
  [ -n "$s" ] || continue
  f="$SCRIPT_DIR/$s"
  if [ -x "$f" ]; then ok "脚本可执行 $s"; else bad "脚本缺失或不可执行 $s"; fi
done < <(python3 -c 'import os,yaml;[print(x) for x in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["scripts"]]')
while IFS= read -r s; do
  [ -n "$s" ] || continue
  if [ -e "$SCRIPT_DIR/$s" ]; then bad "已废止脚本回潮 $s"; else ok "已废止脚本未回潮 $s"; fi
done < <(python3 -c 'import os,yaml;[print(x) for x in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["forbidden_scripts"]]')

echo
echo "== A5) harness 矩阵完整性 =="
MATRIX="$SCRIPT_DIR/harness-matrix.sh"
if [ ! -x "$MATRIX" ]; then bad "缺 harness-matrix.sh"; else
  for h in codebuddy claude codex opencode pi; do
    pre="$(bash "$MATRIX" get "$h" slash_prefix 2>/dev/null || true)"
    cmd="$(bash "$MATRIX" get "$h" start_cmd 2>/dev/null || true)"
    dir="$(bash "$MATRIX" get "$h" skills.dir_project 2>/dev/null || true)"
    if [ -n "$pre" ] && [ -n "$cmd" ] && [ -n "$dir" ]; then ok "harness $h（dir=$dir prefix=$pre）"; else bad "harness $h 字段不完整"; fi
  done
  for h in codebuddy claude codex opencode; do
    [ "$(bash "$MATRIX" get "$h" slash_prefix)" = "/" ] && ok "$h 前缀 /" || bad "$h 前缀应为 /"
  done
  [ "$(bash "$MATRIX" get pi slash_prefix)" = "/skill:" ] && ok "pi 前缀 /skill:" || bad "pi 前缀应为 /skill:"
fi

echo
echo "== A6) 单一来源纪律（技能指针到 team.md，不复述共性口径） =="
while IFS= read -r skill; do
  skill="${skill% }"; [ -n "$skill" ] || continue
  f="$SKILLS_DIR/$skill/SKILL.md"; [ -f "$f" ] || continue
  if grep -qE 'team\.md|docs/team\.md|team/10-pane-role\.md' "$f"; then ok "技能 $skill 指针到 team.md 或公共动作"; else bad "技能 $skill 未指针到 team.md 或公共动作"; fi
done < <(python3 -c 'import os,yaml;[print(k) for k in yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8"))["skills"]]')

echo
echo "== A6b) 按 harness 加载（一份共性 + 每 harness 一份差异） =="
HARNESS_DIR="$REPO/dmt-director/harness"
HARNESS_MATRIX="$REPO/dmt-director/harness_matrix.yaml"
if [ -d "$HARNESS_DIR" ]; then
  for f in $(python3 -c '
import os,yaml
d=yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8")).get("harness_docs") or {}
names=[d.get("readme"), d.get("common")] + list(d.get("per_harness") or [])
print(" ".join(n for n in names if n))'); do
    if [ -s "$HARNESS_DIR/$f" ]; then ok "harness 文件 $f"; else bad "harness 文件缺失或为空：$f"; fi
  done
else
  bad "缺 harness 目录：$HARNESS_DIR"
fi
# harness 改善项的机检锚点（2026-11-06 第八十四次）：BACKLOG 声称已改的项，必须在配置里真实存在
if [ -d "$HARNESS_DIR" ] && [ -s "$HARNESS_DIR/BACKLOG.md" ]; then ok "harness 改善清单 BACKLOG.md"; else bad "缺 harness/BACKLOG.md"; fi
PI_CONC="$(bash "$SCRIPT_DIR/harness-matrix.sh" get pi max_subagents_conc 2>/dev/null || true)"
if [ -n "$PI_CONC" ] && [ "$PI_CONC" != "null" ]; then ok "pi 并发上限已声明（$PI_CONC）"; else bad "pi 并发上限仍为 null（BACKLOG P3 声称已填）"; fi
CBC_CMD="$(bash "$SCRIPT_DIR/harness-matrix.sh" get codebuddy start_cmd 2>/dev/null || true)"
case "$CBC_CMD" in
  *--subagent-permission-mode*) ok "cbc 启动含 --subagent-permission-mode（子代理权限继承）" ;;
  *) bad "cbc 启动缺 --subagent-permission-mode（BACKLOG C2 声称已加）" ;;
esac
CODEX_CMD="$(bash "$SCRIPT_DIR/harness-matrix.sh" get codex start_cmd 2>/dev/null || true)"
case "$CODEX_CMD" in
  *danger-full-access*) ok "codex 启动含 --sandbox danger-full-access" ;;
  *) bad "codex 启动缺 --sandbox danger-full-access（BACKLOG X1 声称已改）" ;;
esac
# 报告与清单必须互相可达（避免"报告说改了、清单没记"）
if grep -q 'BACKLOG.md' "$HARNESS_DIR/README.md" 2>/dev/null; then ok "harness/README.md 指向 BACKLOG"; else bad "harness/README.md 未指向 BACKLOG"; fi
if grep -q 'harness-test-report' "$HARNESS_DIR/BACKLOG.md" 2>/dev/null; then ok "BACKLOG 指向测试报告"; else bad "BACKLOG 未指向测试报告"; fi

# pi 子代理 agent 定义模板（四份 + README）；install-skills.sh 铺到 <target>/.pi/agents/
PI_AG="$HARNESS_DIR/pi-agents"
if [ -d "$PI_AG" ]; then
  for f in README.md dmt-dev-e.md dmt-ana-e.md dmt-pde.md dmt-reviewer.md; do
    if [ -s "$PI_AG/$f" ]; then ok "pi agent 定义 $f"; else bad "pi agent 定义缺失或为空：$f"; fi
  done
  # 每份定义都必须用白名单形态（inheritSkills: false + skills:），否则「精确注入」退化为「全量继承」
  for f in "$PI_AG"/dmt-*.md; do
    b="$(basename "$f")"
    if grep -q '^inheritSkills: false' "$f" && grep -q '^skills:' "$f"; then ok "pi agent $b 用白名单（inheritSkills: false + skills:）"; else bad "pi agent $b 缺 inheritSkills: false 或 skills:"; fi
  done
else
  bad "缺 pi agent 定义目录：$PI_AG"
fi
# install-skills.sh 必须会把模板铺到 .pi/agents/
if grep -q '\.pi/agents' "$SCRIPT_DIR/install-skills.sh"; then ok "install-skills.sh 铺 .pi/agents"; else bad "install-skills.sh 未铺 .pi/agents"; fi

# harness 名集合：契约 per_harness ↔ 矩阵 key（两处必须一一对应）
declared="$(python3 -c '
import os,yaml
d=yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"],encoding="utf-8")).get("harness_docs") or {}
print(" ".join(sorted(x[:-3] for x in (d.get("per_harness") or []) if x.endswith(".md"))))')"
from_matrix="$(python3 -c '
import sys,yaml
print(" ".join(sorted((yaml.safe_load(open(sys.argv[1],encoding="utf-8")).get("harnesses") or {}).keys())))' "$HARNESS_MATRIX")"
if [ "$declared" = "$from_matrix" ]; then ok "harness 差异文件与矩阵 key 一致（$declared）"; else bad "harness 差异文件与矩阵 key 不一致：契约=[$declared] 矩阵=[$from_matrix]"; fi
# 技能第 0 步：七份技能都必须指向检测脚本（内容断言另有一组同据）
for s in dmt-director dmt-dm dmt-am dmt-pde dmt-de dmt-ae dmt-reviewer; do
  f="$SKILLS_DIR/$s/SKILL.md"
  [ -f "$f" ] || continue
  if grep -q 'harness-detect.sh' "$f"; then ok "技能 $s 含第 0 步（harness-detect.sh）"; else bad "技能 $s 缺第 0 步（harness-detect.sh）"; fi
done
# 检测脚本自测：五 harness + 未知（未知必须 rc=1，不得沉默默认）
DETECT="$SCRIPT_DIR/harness-detect.sh"
if [ -x "$DETECT" ]; then ok "harness-detect.sh 可执行"; else bad "harness-detect.sh 缺失或不可执行"; fi
detect_case() {
  local argv="$1" want="$2" out rc
  out="$(env -i PATH="$PATH" HOME="${HOME:-/tmp}" DMT_PANE_ARGV="$argv" DMT_DETECT_NO_PARENT=1 bash "$DETECT" 2>/dev/null)"; rc=$?
  if [ "$out" = "$want" ]; then ok "harness-detect: [$argv] ⇒ $want"; else bad "harness-detect: [$argv] ⇒ [$out]（期望 $want）"; fi
  return 0
}
if [ -x "$DETECT" ]; then
  detect_case "pi --approve" pi
  detect_case "/opt/codex" codex
  detect_case "node /x/bin/cbc -c" codebuddy
  detect_case "claude --settings a.json" claude
  detect_case "opencode --auto" opencode
  unknown_out="$(env -i PATH="$PATH" HOME="${HOME:-/tmp}" DMT_PANE_ARGV="/usr/bin/vim" DMT_DETECT_NO_PARENT=1 bash "$DETECT" 2>/dev/null)"; unknown_rc=$?
  if [ "$unknown_out" = "unknown" ] && [ "$unknown_rc" = 1 ]; then ok "harness-detect: 判不出 ⇒ unknown（rc=1）"; else bad "harness-detect: 判不出时应输出 unknown 且 rc=1（实得 out=$unknown_out rc=$unknown_rc）"; fi
fi

echo
echo "== A6c) pi agent 白名单可注入性 =="
# 判据：pi 的子代理 `skills:` 对 `disable-model-invocation: true` 的技能**静默过滤**
# （2026-11-06 实测：声明 5 个只注入 4 个，to-spec/to-tickets 双双丢失且无告警）。
# ⇒ 白名单只许写「无该标记」的技能；被过滤的技能改由 agent prompt 给 SKILL.md 路径。
# 找不到技能目录时只 WARN（第三方技能可能未装在当前环境），不误报失败。
A6C_OUT="$(python3 - "$REPO" "$ROOT" <<'PYSK'
import os, re, sys, glob
repo, root = sys.argv[1], sys.argv[2]
home = os.path.expanduser("~")
roots = [
    os.path.join(root, ".agents", "skills"),
    os.path.join(repo, ""),
    os.path.join(home, ".agents", "skills"),
    os.path.join(home, ".pi", "agent", "skills"),
]
mm = os.path.join(home, ".pi", "agent", "git", "github.com", "mattpocock", "skills", "skills")
if os.path.isdir(mm):
    roots += [d for d in glob.glob(os.path.join(mm, "*")) if os.path.isdir(d)]

def find(name):
    for r in roots:
        p = os.path.join(r, name, "SKILL.md")
        if os.path.isfile(p):
            return p
    p = os.path.join(repo, name, "SKILL.md")
    return p if os.path.isfile(p) else None

for f in sorted(glob.glob(os.path.join(repo, "dmt-director", "harness", "pi-agents", "dmt-*.md"))):
    txt = open(f, encoding="utf-8").read()
    m = re.search(r"^skills:\s*(.+)$", txt, re.M)
    base = os.path.basename(f)
    if not m:
        print("WARN\t%s\t(no skills field)" % base)
        continue
    for n in [x.strip() for x in m.group(1).split(",") if x.strip()]:
        p = find(n)
        if not p:
            print("WARN\t%s\t%s\tnot installed in this environment" % (base, n))
            continue
        head = open(p, encoding="utf-8").read()[:1200]
        if re.search(r"^disable-model-invocation:\s*true", head, re.M):
            print("FAIL\t%s\t%s\tfiltered by disable-model-invocation (move to prompt path)" % (base, n))
        else:
            print("OK\t%s\t%s" % (base, n))
PYSK
)"
a6c_fail=0
while IFS=$'\t' read -r st who what extra; do
  [ -n "${st:-}" ] || continue
  case "$st" in
    OK)   ok "pi agent $who: $what 可注入" ;;
    WARN) ok "pi agent $who: $what 跳过（$extra）" ;;
    FAIL) bad "pi agent $who: $what —— $extra"; a6c_fail=1 ;;
  esac
done <<< "$A6C_OUT"
[ "$a6c_fail" = 0 ] || fail=1

echo "== A7) 文档相对链接可达 =="
REPO_REAL="$(readlink -f "$REPO")"
SKILLS_REAL="$(readlink -f "$SKILLS_DIR")"
ROOT_REAL="$(readlink -f "$ROOT")"
DIRNAME="$(dirname "$SKILLS_REAL")"
IN_REPO=0
[ "$ROOT_REAL" = "$REPO_REAL" ] && [ "$SKILLS_REAL" = "$REPO_REAL" ] && IN_REPO=1
while IFS=$'\t' read -r src target; do
  # 项目技能安装可为真实目录或指向仓内的软链。两种都要从安装位置起解析：
  # 角色的 ../dmt-director 指项目根，而不是仓内目录。
  unset src_root
  if [ "$IN_REPO" -eq 1 ]; then
    src_root=""
  else
    case "$src" in
      "$SKILLS_REAL"/dmt-*/SKILL.md) src_root="$SKILLS_REAL" ;;
    esac
  fi
  if [ "$IN_REPO" -ne 1 ]; then
    [ -n "${src_root:-}" ] || src_root="$(dirname "$(readlink -f "$src")")"
  fi
  target="${target%%#*}"
  target="${target%%\?*}"
  [ -n "$target" ] || continue
  case "$target" in
    http://*|https://*|mailto:*|/*) continue ;;
  esac
  # 仓内正本拆成「仓根」与「技能安装目录」两种相对链，两种都必须命中；
  # 安装后则先从技能安装位置解析，再从项目根解析。
  if [ "$IN_REPO" -eq 1 ]; then
    target_real="${target#../}"
    case "$src" in
      "$REPO"/dmt-*/SKILL.md) dest="$(dirname "$src")/$target" ;;
      *) dest="$(dirname "$src")/$target_real" ;;
    esac
  elif [ -n "$src_root" ]; then
    dest="$DIRNAME/$target"
  else
    dest="$target"
  fi
  alt="$DIRNAME/$target"
  if [ -e "$dest" ] || [ -e "$(dirname "$src")/$target" ] ||
     { [ "$IN_REPO" -eq 0 ] && [ -e "$ROOT/docs/ops/$target" ]; } ||
     { [ "$IN_REPO" -eq 0 ] && { [ -e "$alt" ] || [ -e "$ROOT/$target" ] || [ -e "$ROOT/dmt-director/$target" ]; }; }; then
    ok "链接 ${src#$REPO/} -> $target"
  elif [ "$IN_REPO" -eq 1 ] && [ -e "$target" ]; then
    ok "链接 ${src#$REPO/} -> $target"
  else
    bad "断链 ${src#$REPO/} -> $target"
  fi
done < <(python3 - "$REPO" "$DOCS_DIR" <<'PY'
import os, re, sys
repo, docs = map(os.path.abspath, sys.argv[1:3])
files = []
for root in (repo, docs):
    for dirpath, _, names in os.walk(root):
        if "/.git" in dirpath or "/changelog" in dirpath:
            continue
        for name in names:
            if name.endswith(".md"):
                files.append(os.path.join(dirpath, name))
pattern = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+[^)]*)?\)")
seen = set()
for src in sorted(set(files)):
    try:
        text = open(src, encoding="utf-8").read()
    except OSError:
        continue
    # 排除围栏代码块与行内代码里的伪链接（2026-11-05 实测噪声源：`x[i]`、`+out1`、`[a-z0-9_]+`）
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    text = re.sub(r"`[^`]*`", "", text)
    for target in pattern.findall(text):
        key = (src, target)
        if key not in seen:
            seen.add(key)
            print(f"{src}\t{target}")
PY
)

# ---------- B. 内容断言（原 check-dmt-doc-paths.sh 的散文 grep，收口到 YAML） ----------
echo
echo "===== B. 内容断言（dmt_contract.yaml: content_assertions） ====="
# 把 YAML 断言表展开成 TAB 分隔行：path<TAB>require<TAB>forbid<TAB>who
ASSERT_TSV="$(DMT_IS_REPO="$DMT_IS_REPO" python3 - <<'PY'
import os, yaml
m = yaml.safe_load(open(os.environ["DMT_CONTRACT_YAML"], encoding="utf-8"))
for group, spec in (m.get("content_assertions") or {}).items():
    if spec.get("repo_only") and os.environ.get("DMT_IS_REPO") != "1":
        continue
    for path, rules in (spec.get("files") or {}).items():
        req = "|".join(rules.get("require", []))
        forb = "|".join(rules.get("forbid", []))
        print(f"{group}\t{path}\t{req}\t{forb}")
PY
)"
while IFS=$'\t' read -r group tmpl req forb; do
  [ -n "$tmpl" ] || continue
  path="$tmpl"
  path="${path//\{docs\}/$DOCS_DIR}"
  path="${path//\{skills\}/$SKILLS_DIR}"
  path="${path//\{scripts\}/$SCRIPT_DIR}"
  path="${path//\{repo\}/$REPO}"
  # team/*.md 只随 dmt-director/ 安装（不软链进 docs/）；缺失时回退到安装副本。
  if [ ! -f "$path" ]; then
    case "$tmpl" in
      "{docs}/team/"*) alt="$ROOT/dmt-director/${tmpl#\{docs\}/}"; [ -f "$alt" ] && path="$alt" ;;
    esac
  fi
  who="$group:$(basename "$(dirname "$path")")/$(basename "$path")"
  if [ ! -f "$path" ]; then bad "$who 文件不存在（$path）"; continue; fi
  if [ -n "$req" ]; then
    miss=""
    while IFS= read -r r; do
      [ -n "$r" ] || continue
      grep -qF -- "$r" "$path" 2>/dev/null || miss="$miss [$r]"
    # 末尾必须带换行：`printf '%s'` 无尾换行时，read 遇 EOF 返回非 0，
    # 循环会静默丢掉最后一条 require（实测：单条 require 的断言 100% 未执行却报 OK）
    done < <(printf '%s\n' "$req" | tr '|' '\n')
    if [ -n "$miss" ]; then bad "$who 缺要求串：$miss"; else ok "$who 含全部要求串"; fi
  fi
  if [ -n "$forb" ]; then
    hit=""
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if grep -qE -- "$p" "$path" 2>/dev/null; then hit="$hit /$p/"; fi
    done < <(printf '%s\n' "$forb" | tr '|' '\n')
    if [ -n "$hit" ]; then bad "$who 含禁用串：$hit"; else ok "$who 不含禁用串"; fi
  fi
done <<< "$ASSERT_TSV"

echo
if [ "$fail" = 0 ]; then echo "ALL_PASS"; else echo "HAS_FAIL"; fi
exit "$fail"
