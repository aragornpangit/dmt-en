#!/usr/bin/env bash
# 收件方收口：办完后从 inbox/<role>/.doing/ 删除该消息
# 用法：bash msg-done.sh <role> <file>
set -eu
ROLE="${1:?usage: msg-done.sh <role> <file>}"
FILE="${2:?missing file}"
# 角色白名单：director|devm|anam，非法 exit 2（helper 无自己的 inbox，不作收件角色）
case "$ROLE" in
  director|devm|anam) ;;
  *) echo "bad role: $ROLE (want director|devm|anam)" >&2; exit 2 ;;
esac
# 收件箱定位到主工作树根
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"; . "$DIR/lib-dmt.sh"
ROOT="$(dmt_root)"
BOX="$ROOT/inbox/$ROLE"
NAME="$(basename "$FILE")"
SRC="$BOX/.doing/$NAME"
[ -f "$SRC" ] || { echo "not in .doing: $SRC" >&2; exit 2; }
rm -f "$SRC"
echo "done: $NAME"
