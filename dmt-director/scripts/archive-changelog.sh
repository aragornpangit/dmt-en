#!/usr/bin/env bash
# archive-changelog.sh —— 把非当前季度的变更条目从 CHANGELOG.md 归档到 changelog/<YYYYQn>.md（工程卫生 §5）
#
# 目的：CHANGELOG.md 只保留**最新季度**条目，历史按季度归档，避免单文件无限膨胀。
# 纪律：条目**整条原样搬移**（不改写、不重编号，符合「历史留痕」）。
#
# 用法：
#   bash archive-changelog.sh [--dry-run]         # 归档非最新季度的条目
#   bash archive-changelog.sh --keep N [--dry-run] # 只保留最新 N 条，其余归档到 changelog/archive.md
#   bash archive-changelog.sh --check             # 只报告条目总数与跨季度条数，不改动
#
# 说明：条目跨越其季度的判定按条目首行日期（- **YYYY-MM-DD …）。归档文件按时间倒序。
set -eu
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"
REPO="$(cd -P "$DIR/../.." && pwd -P)"
export CL="$REPO/dmt-director/CHANGELOG.md" ARCH_DIR="$REPO/dmt-director/changelog"
DRY=0; CHECK=0; KEEP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --check) CHECK=1; shift ;;
    --keep) KEEP="${2:?missing N}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
export DRY CHECK KEEP
[ -f "$CL" ] || { echo "archive-changelog: 缺 $CL" >&2; exit 2; }

python3 - <<'PY'
import os, re
cl = os.environ["CL"]; ad = os.environ["ARCH_DIR"]
dry = os.environ["DRY"] == "1"; check = os.environ["CHECK"] == "1"
lines = open(cl, encoding="utf-8").read().split("\n")

# 拆「头部（首条之前）」+ 条目列表；条目跨续行到下一个 "- **YYYY-..." 为止
header, entries, cur = [], [], None
for ln in lines:
    m = re.match(r"- \*\*(\d{4})-(\d{2})-\d{2}", ln)
    if m:
        if cur: entries.append(cur)
        y, mo = int(m.group(1)), int(m.group(2))
        cur = {"q": f"{y}Q{(mo-1)//3+1}", "lines": [ln]}
    elif cur:
        cur["lines"].append(ln)
    else:
        header.append(ln)
if cur: entries.append(cur)

if check:
    nq = entries[0]["q"] if entries else "(空)"
    old = sum(1 for e in entries if e["q"] != nq)
    print(f"条目总数：{len(entries)}；最新季度：{nq}；可归档（非最新季度）：{old}")
    raise SystemExit(0)

if not entries:
    print("CHANGELOG.md 无条目，跳过"); raise SystemExit(0)

keep_n = os.environ.get("KEEP", "").strip()
if keep_n:
    n = int(keep_n)
    keep = entries[:n]
    archived = entries[n:]
    groups = {"archive": archived} if archived else {}
    newest_q = "(--keep %d)" % n
else:
    newest_q = entries[0]["q"]
    keep = [e for e in entries if e["q"] == newest_q]
    groups = {}
    for e in entries:
        if e["q"] != newest_q: groups.setdefault(e["q"], []).append(e)

def render(es): return "\n".join("\n".join(e["lines"]).rstrip("\n") for e in es) + "\n"

if not groups:
    print(f"无需归档：全部 {len(entries)} 条都在最新季度 {newest_q}"); raise SystemExit(0)

os.makedirs(ad, exist_ok=True)
for q in sorted(groups, reverse=True):
    path = os.path.join(ad, f"{q}.md")
    body = (f"# dmt 团队契约 · 变更记录归档（{q}）\n\n"
            f"> 从 CHANGELOG.md 归档（整条原样搬移，不改写、不重编号）。\n\n" + render(groups[q]))
    if dry: print(f"[dry] 写 {path}（{len(groups[q])} 条）")
    else: open(path, "w", encoding="utf-8").write(body); print(f"归档 {q} → {path}（{len(groups[q])} 条）")

note = "\n> 更早季度已归档：" + ", ".join(f"`changelog/{q}.md`" for q in sorted(groups, reverse=True)) + "\n"
head = "\n".join(header).rstrip("\n")
out = head + "\n" + note + "\n" + render(keep)
if dry: print(f"[dry] CHANGELOG.md 保留 {len(keep)} 条（最新季度 {newest_q}）")
else: open(cl, "w", encoding="utf-8").write(out); print(f"CHANGELOG.md 保留 {len(keep)} 条（{newest_q}）")
PY
