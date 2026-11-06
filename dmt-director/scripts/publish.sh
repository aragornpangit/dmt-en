#!/usr/bin/env bash
# devm 用（merge 与 push 归 devm）：显式路径提交并推送到 GitLab + GitHub（每 ticket 一推 / 每小时巡检）
# 用法：bash publish.sh -m <message> [--auto] [--no-push] [--remotes "gitlab origin"] -- <paths...>
#   --auto 由 git status 枚举改动路径（仍是显式路径，不用 git add -A）
set -eu
# 载入 .env（DMT_GITLAB_SERVER / DMT_GITLAB_PORT / DMT_GITLAB_REPO；已导出的环境变量优先）
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$DIR/lib-dmt.sh"
dmt_load_env
MSG=""; AUTO=0; PUSH=1; REMOTES="gitlab origin"
PATHS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -m) MSG="${2:?missing message}"; shift 2 ;;
    --auto) AUTO=1; shift ;;
    --no-push) PUSH=0; shift ;;
    --remotes) REMOTES="${2:?missing remotes}"; shift 2 ;;
    --) shift; PATHS=("$@"); break ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$MSG" ] || { echo "missing -m <message>" >&2; exit 2; }

if [ "$AUTO" = 1 ]; then
  # -z + core.quotePath=false：空格 / 中文 / 重命名都不丢；删除项也收进来（git add -A 能记录删除）
  PATHS=()
  declare -A seen=()
  add_path() {
    [ -n "$1" ] || return 0
    [ -n "${seen[$1]:-}" ] && return 0
    seen[$1]=1; PATHS+=("$1")
  }
  while IFS= read -r -d '' p; do add_path "$p"; done \
    < <(git -c core.quotePath=false ls-files -z --modified --deleted --others --exclude-standard)
  if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    while IFS= read -r -d '' p; do add_path "$p"; done \
      < <(git -c core.quotePath=false diff --cached --name-only -z HEAD)
  fi
fi
[ "${#PATHS[@]}" -gt 0 ] || { echo "nothing to commit"; exit 0; }

# 显式列路径：先 add 指定路径（-A 才能记录已删除文件）
git add -A -- "${PATHS[@]}"
if git diff --cached --quiet; then echo "nothing to commit"; exit 0; fi

# 提交不能带 pathspec：已删除路径在 index 里已无条目，`git commit -- <path>` 会报
# "pathspec ... did not match any files"（一次重命名就能让 --auto 永久卡死）。
# 改为「索引里只许出现本次列出的路径」再整体提交，既保住显式路径语义，又能记录删除。
contains() { local x="$1" p; for p in "${PATHS[@]}"; do [ "$p" = "$x" ] && return 0; done; return 1; }
while IFS= read -r -d '' p; do
  contains "$p" || { echo "ERROR: 索引里还有未列入本次提交的改动：$p（先单独提交或 stash）" >&2; exit 2; }
done < <(git -c core.quotePath=false diff --cached --name-only -z)

git commit -m "$MSG"

if [ "$PUSH" = 1 ]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
  for r in $REMOTES; do
    git push "$r" "HEAD:${branch}"
  done
fi
