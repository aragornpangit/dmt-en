#!/usr/bin/env bash
# Recipient claim: move a message from inbox/<role>/ into inbox/<role>/.doing/ (claim before reading)
# Usage: bash msg-take.sh <role> <file>        file may be a name or a path; basename is used
set -eu
ROLE="${1:?usage: msg-take.sh <role> <file>}"
FILE="${2:?missing file}"
# Role allowlist: director|devm|anam; anything else exits 2 (a helper has no inbox of its own, so it is never a recipient role)
case "$ROLE" in
  director|devm|anam) ;;
  *) echo "bad role: $ROLE (want director|devm|anam)" >&2; exit 2 ;;
esac
# Locate the inbox at the main worktree root (same rule as dispatch-ledger)
DIR="$(cd "$(dirname "$0")" && pwd)"; . "$DIR/lib-dmt.sh"
ROOT="$(dmt_root)"
BOX="$ROOT/inbox/$ROLE"
NAME="$(basename "$FILE")"
SRC="$BOX/$NAME"
[ -f "$SRC" ] || { echo "not found: $SRC" >&2; exit 2; }
mkdir -p "$BOX/.doing"
[ -e "$BOX/.doing/$NAME" ] && { echo "already taken: $NAME" >&2; exit 3; }
mv "$SRC" "$BOX/.doing/$NAME"
echo "$BOX/.doing/$NAME"
