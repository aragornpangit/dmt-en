#!/usr/bin/env bash
# Recipient claim: move a message from inbox/<role>/ into inbox/<role>/.doing/ (claim before reading)
# Usage: bash msg-take.sh <role> <file>        file may be a name or a path; basename is used
set -eu
ROLE="${1:?usage: msg-take.sh <role> <file>}"
FILE="${2:?missing file}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BOX="$ROOT/inbox/$ROLE"
NAME="$(basename "$FILE")"
SRC="$BOX/$NAME"
[ -f "$SRC" ] || { echo "not found: $SRC" >&2; exit 2; }
mkdir -p "$BOX/.doing"
[ -e "$BOX/.doing/$NAME" ] && { echo "already taken: $NAME" >&2; exit 3; }
mv "$SRC" "$BOX/.doing/$NAME"
echo "$BOX/.doing/$NAME"
