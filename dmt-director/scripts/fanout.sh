#!/usr/bin/env bash
# One-shot parallel dispatcher: expand a unit list into dispatch prompts filled in from the team.md §5.2 skeleton (one per unit)
# Usage: fanout.sh <role> <units-file> [--cap N]
#   units-file has one unit per line, TAB separated: unit name <TAB> input path <TAB> boundary (Files) <TAB> product <TAB> criteria <TAB> timeoutMs
#   --cap N: concurrency for this batch, open on demand, capped at 8 (non-numeric or > 8 counts as 8, floor 1)
# Output: a dispatch plan + one prompt per unit; the model dispatches min(N, CAP) sub-agents concurrently within the same reply (open on demand, capped at min(8, cap)).
set -eu
ROLE="${1:?usage: fanout.sh <role> <units-file> [--cap N]}"
UNITS="${2:?missing units file}"
CAPARG=""
if [ "${3:-}" = "--cap" ]; then CAPARG="${4:?--cap needs a value}";
elif [ -n "${3:-}" ]; then echo "unknown arg: $3 (only --cap N is accepted)" >&2; exit 2; fi
[ -f "$UNITS" ] || { echo "units file not found: $UNITS" >&2; exit 2; }
DIR="$(cd "$(dirname "$0")" && pwd)"
CAP="${CAPARG:-$(bash "$DIR/probe-cap.sh")}"
# --cap caps at 8: non-numeric or > 8 counts as 8, floor 1
case "$CAP" in ''|*[!0-9]*) CAP=8 ;; esac
CAP=$((10#$CAP))
if [ "$CAP" -gt 8 ]; then CAP=8; fi
if [ "$CAP" -lt 1 ]; then CAP=1; fi
n=0
echo "dispatch plan: role=$ROLE CAP=$CAP (open on demand, capped at min(8, cap); when N exceeds the cap, batch it and top up the dispatch before closing out after a wake-up)"
echo "---"
while IFS=$'\t' read -r unit input bounds product criteria timeout; do
  [ -n "$unit" ] || continue
  n=$((n + 1))
  wave=$(( (n - 1) / CAP + 1 ))
  echo "[unit $n · wave $wave] sub-agent prompt:"
  echo "You are a sub-agent of $ROLE. Unit: $unit. Input: $input. Boundary: $bounds. Product: $product. Criteria: $criteria. Report: conclusion + evidence (first-hand source / reproducible command) + grade [OBS]/[INF]/[UNK]. Timeout: ${timeout:-2700000}."
  echo "---"
done < "$UNITS"
echo "$n units total: first book them with dispatch-ledger.sh plan $ROLE <unit-names...> (dispatch first), then dispatch min($n, $CAP) concurrently within the same reply (open on demand, capped at min(8, cap), run_in_background: true); when N exceeds the cap, batch it and top up the dispatch before closing out after a wake-up."
