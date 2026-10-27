#!/usr/bin/env bash
# Recipient close-out: delete the message from inbox/<role>/.doing/ once the work is done
# Usage: bash msg-done.sh <role> <file>
set -eu
ROLE="${1:?usage: msg-done.sh <role> <file>}"
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
SRC="$BOX/.doing/$NAME"
[ -f "$SRC" ] || { echo "not in .doing: $SRC" >&2; exit 2; }
rm -f "$SRC"
echo "done: $NAME"
