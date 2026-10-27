#!/usr/bin/env bash
# For devm (merge and push belong to devm alone): commit explicit paths and push to GitLab + GitHub (push at least once per completed ticket / at least hourly)
# Usage: bash publish.sh -m <message> [--auto] [--no-push] [--remotes "gitlab origin"] -- <paths...>
#   --auto enumerates changed paths from git status (still explicit paths, no git add -A)
set -eu
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
  # -z + core.quotePath=false: spaces / Unicode / renames are not lost; deletions are collected too (git add -A records deletions)
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

# Explicit path list: add the given paths first (-A is what records deleted files)
git add -A -- "${PATHS[@]}"
if git diff --cached --quiet; then echo "nothing to commit"; exit 0; fi

# A commit must not carry a pathspec: a deleted path no longer has an index entry, so `git commit -- <path>`
# reports "pathspec ... did not match any files" (a single rename can wedge --auto forever).
# Instead, assert that only the paths listed this time may appear in the index, then commit as a whole:
# this keeps the explicit-path semantics and still records deletions.
contains() { local x="$1" p; for p in "${PATHS[@]}"; do [ "$p" = "$x" ] && return 0; done; return 1; }
while IFS= read -r -d '' p; do
  contains "$p" || { echo "ERROR: the index still has changes not listed in this commit: $p (commit or stash them separately first)" >&2; exit 2; }
done < <(git -c core.quotePath=false diff --cached --name-only -z)

git commit -m "$MSG"

if [ "$PUSH" = 1 ]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
  for r in $REMOTES; do
    git push "$r" "HEAD:${branch}"
  done
fi
