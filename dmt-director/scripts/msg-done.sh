#!/usr/bin/env bash
# Recipient close-out: delete the message from inbox/<role>/.doing/ once the work is done
# Usage: bash msg-done.sh <role> <file>
set -eu
ROLE="${1:?usage: msg-done.sh <role> <file>}"
FILE="${2:?missing file}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BOX="$ROOT/inbox/$ROLE"
NAME="$(basename "$FILE")"
SRC="$BOX/.doing/$NAME"
[ -f "$SRC" ] || { echo "not in .doing: $SRC" >&2; exit 2; }
rm -f "$SRC"
echo "done: $NAME"
