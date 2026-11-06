#!/usr/bin/env bash
# digest-changelog.sh —— 为 CHANGELOG 生成语义摘要（工程卫生 §5）
#
# 目的：CHANGELOG 全文很长；生成一份**每条约一行的语义摘要**（标题 + 版本 + 首句要点），
# 供快速回溯。摘要**不改写历史**（全文仍在 CHANGELOG.md）；摘要只是索引。
#
# 用法：bash digest-changelog.sh [--dry-run]
#   输出：dmt-director/CHANGELOG-DIGEST.md
set -eu
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"
REPO="$(cd -P "$DIR/../.." && pwd -P)"
CL="$REPO/dmt-director/CHANGELOG.md"
OUT="$REPO/dmt-director/CHANGELOG-DIGEST.md"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
[ -f "$CL" ] || { echo "digest-changelog: 缺 $CL" >&2; exit 2; }
export CL OUT DRY

python3 - <<'PY'
import os, re
cl=os.environ["CL"]; out=os.environ["OUT"]; dry=os.environ["DRY"]=="1"
# 读取 CHANGELOG.md + 其归档目录（changelog/*.md），合并后按日期倒序去重
srcs=[cl]
arch=os.path.join(os.path.dirname(cl),"changelog")
if os.path.isdir(arch):
    for fn in sorted(os.listdir(arch)):
        if fn.endswith(".md"): srcs.append(os.path.join(arch,fn))
lines=[]
for s in srcs:
    lines += open(s,encoding="utf-8").read().split("\n")
rows=[]
cur=None
for ln in lines:
    m=re.match(r"- \*\*(\d{4}-\d{2}-\d{2})（(.+?)）\*\*：(.*)", ln)
    if m:
        if cur: rows.append(cur)
        cur={"date":m.group(1),"label":m.group(2),"body":m.group(3)}
    elif cur is not None:
        cur["body"]+=" "+ln
if cur: rows.append(cur)

# 去重（同一条目可能被 CHANGELOG 与归档各扫到一次）
seen=set(); dedup=[]
for r in rows:
    key=(r["date"], r["label"][:60])
    if key in seen: continue
    seen.add(key); dedup.append(r)
rows=dedup

def ver(b, lab=""):
    m=re.search(r"版本\s*`?([0-9]+\.[0-9]+\.[0-9]+)`?", b) or re.search(r"版本\s*`?([0-9]+\.[0-9]+\.[0-9]+)`?", lab)
    return m.group(1) if m else "—"
def lead(b):
    # 去 markdown 强调，取首句
    t=re.sub(r"[*`]", "", b).strip()
    t=re.split(r"[。；;]", t)[0]
    return t[:80]

out_lines=["# dmt 变更语义摘要（自动生成，勿手改）","",
        f"> 由 `digest-changelog.sh` 从 [`CHANGELOG.md`](CHANGELOG.md) 及其归档（`changelog/`）生成；每条约一行语义摘要，全文以 CHANGELOG.md + 归档为准。共 {len(rows)} 条。","",
        "| 日期 | 条目 | 版本 | 要点 |","|---|---|---|---|"]
for r in rows:
    lab=r["label"].replace("|","/")
    lab_disp = lab
    out_lines.append(f"| {r['date']} | {lab_disp} | {ver(r['body'], r['label'])} | {lead(r['body'])} |")
body="\n".join(out_lines)+"\n"
if dry: print(f"[dry] 将写 {out}（{len(rows)} 条）")
else: open(out,"w",encoding="utf-8").write(body); print(f"已写 {out}（{len(rows)} 条）")
PY
