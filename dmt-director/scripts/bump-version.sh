#!/usr/bin/env bash
# bump-version.sh —— 版本单一来源同步（工程卫生 §4）
#
# 版本号的权威在 dmt-director/dmt_contract.yaml 的 `version:`（+ `date:`）。
# 本脚本把该版本刷进全部 version_sources（team.md 头部 + 七份 SKILL.md 的 frontmatter），
# 一条命令替代原来「手改 8 处 + 靠机检发现漏改」。
#
# 用法：
#   bash bump-version.sh <X.Y.Z> [--date YYYY-MM-DD] [--dry-run]
#   bash bump-version.sh --check          # 只校验是否同号（同 check-dmt.sh 第 1 节）
#
# 改完请跑 `bash check-dmt.sh` 确认 ALL_PASS。
set -eu
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"
REPO="$(cd -P "$DIR/../.." && pwd -P)"
YAML="$REPO/dmt-director/dmt_contract.yaml"
[ -f "$YAML" ] || { echo "bump-version: 缺 $YAML" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 || {
  echo "bump-version: 需要 python3 + PyYAML" >&2; exit 3; }

VER=""; DATE=""; DRY=0; CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --date) DATE="${2:?missing date}"; shift 2 ;;
    -*) echo "unknown arg: $1" >&2; exit 2 ;;
    *) VER="$1"; shift ;;
  esac
done

if [ "$CHECK" = 1 ]; then
  # 第 1 节即版本同号校验（其余节也会跑）；技能目录指向仓内（各角色目录即技能目录）
  DMT_SKILLS_DIR="$REPO" exec bash "$DIR/check-dmt.sh" "$REPO"
fi
[ -n "$VER" ] || { echo "usage: bump-version.sh <X.Y.Z> [--date YYYY-MM-DD] [--dry-run]" >&2; exit 2; }
case "$VER" in *[!0-9.]*|.*|*.) echo "版本号格式应为 X.Y.Z：$VER" >&2; exit 2 ;; esac
[ -n "$DATE" ] || DATE="$(date +%F)"

export VER DATE DRY YAML REPO
python3 - <<'PY'
import os, re, yaml
yaml_path = os.environ["YAML"]; repo = os.environ["REPO"]
ver = os.environ["VER"]; date = os.environ["DATE"]; dry = os.environ["DRY"] == "1"
m = yaml.safe_load(open(yaml_path, encoding="utf-8"))
# 1) 更新 yaml 自身
txt = open(yaml_path, encoding="utf-8").read()
txt = re.sub(r'(?m)^version: .*$', f"version: {ver}", txt)
txt = re.sub(r'(?m)^date: .*$', f'date: "{date}"', txt)
if not dry:
    open(yaml_path, "w", encoding="utf-8").write(txt)
print(("DRY " if dry else "") + f"yaml version -> {ver} ({date})")
# 2) 更新每个 version_source
for rel in m["version_sources"]:
    p = os.path.join(repo, rel)
    s = open(p, encoding="utf-8").read()
    if rel.endswith("team.md"):
        s2 = re.sub(r'版本 [0-9]+\.[0-9]+\.[0-9]+ · [0-9-]+', f'版本 {ver} · {date}', s, count=1)
    else:
        s2 = re.sub(r'(?m)^version: .*$', f"version: {ver}", s, count=1)
    if s2 == s:
        print(f"WARN 未变化（版本串可能已一致或格式不符）：{rel}")
    else:
        if not dry:
            open(p, "w", encoding="utf-8").write(s2)
        print(("DRY " if dry else "") + f"{rel} -> {ver}")
PY

if [ "$DRY" = 1 ]; then echo "（--dry-run：未写盘）"; else
  echo "已同步版本 $VER（$DATE）；跑 check-dmt.sh 复核"
fi
