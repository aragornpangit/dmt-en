#!/usr/bin/env bash
# 初始化被服务项目的目录与 .gitignore，并跑一次机检（幂等）
# 用法：bash init-project.sh [项目根目录] [--no-check]（默认当前目录）
#   --no-check 只建目录与 .gitignore，不跑机检（技能还没装时用，否则机检必然 HAS_FAIL）
set -eu
ROOT=""; CHECK=1
for a in "$@"; do
  case "$a" in
    --no-check) CHECK=0 ;;
    -*) echo "unknown option: $a" >&2; exit 2 ;;
    *) ROOT="$(cd -P "$a" && pwd -P)" ;;
  esac
done
[ -n "$ROOT" ] || ROOT="$PWD"
SCRIPT_DIR="$(cd -P "$(dirname "$0")" && pwd -P)"

mkdir -p "$ROOT"/docs/{pd/{prd,spec},dev/tickets,analyst,human/{human-arch,human-plan},handoff} \
         "$ROOT"/inbox/{director,devm,anam} "$ROOT"/locks

# __pycache__/ 与 *.pyc：2026-11-05 实测——子代理的 python 探针会在目标项目留下 .pyc（不在交付物内）
for line in 'inbox/*/' 'locks/' '.codebuddy/' '__pycache__/' '*.pyc'; do
  grep -qxF "$line" "$ROOT/.gitignore" 2>/dev/null || echo "$line" >> "$ROOT/.gitignore"
done

echo "initialized: $ROOT"
if [ "$CHECK" = 1 ]; then
  bash "$SCRIPT_DIR/check-dmt.sh" "$ROOT"
else
  echo "skip check（--no-check）；装好技能后再跑 bash $SCRIPT_DIR/check-dmt.sh \"$ROOT\""
fi
