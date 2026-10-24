#!/usr/bin/env bash
# For director: commit explicit paths and push to GitLab + GitHub (one push per ticket / hourly patrol)
# Usage: bash publish.sh -m <message> [--auto] [--no-push] [--remotes "gitlab origin"] -- <paths...>
#   --auto enumerates changed paths from git status --porcelain (still explicit paths, no git add -A)
set -eu
MSG=""; AUTO=0; PUSH=1; REMOTES="gitlab origin"; PATHS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -m) MSG="${2:?missing message}"; shift 2 ;;
    --auto) AUTO=1; shift ;;
    --no-push) PUSH=0; shift ;;
    --remotes) REMOTES="${2:?missing remotes}"; shift 2 ;;
    --) shift; PATHS="$*"; break ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$MSG" ] || { echo "missing -m <message>" >&2; exit 2; }

if [ "$AUTO" = 1 ]; then
  PATHS="$(git status --porcelain | sed 's/^...//' | tr '\n' ' ')"
fi
[ -n "${PATHS// /}" ] || { echo "nothing to commit"; exit 0; }

# Explicit path list: add the given paths first, then commit those paths
# shellcheck disable=SC2086
git add -- $PATHS
# shellcheck disable=SC2086
git commit -m "$MSG" -- $PATHS

if [ "$PUSH" = 1 ]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
  for r in $REMOTES; do
    git push "$r" "HEAD:${branch}"
  done
fi
