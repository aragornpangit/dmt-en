#!/usr/bin/env bash
# Dispatch ledger: turns "every dependency-free unit must be dispatched" into a machine-checkable hard rule
# Usage:
#   plan   <role> <unit...>        declare this batch's dependency-free units (resets the ledger)
#   inc    <role> [unit]           book one dispatch (called by the PostToolUse hook after an Agent call)
#   excuse <role> <unit> <code>    record an exemption, code in dep|files|build|order|device|rea|atomic
#   done   <role> <unit>           mark a unit as closed out
#   check  <role>                  rc=0 when compliant; rc=2 while units are undispatched (the Stop hook blocks on rc=2)
#   report <role>                  print the paste-ready concurrency ledger line
#   status <role>
set -eu
CMD="${1:?usage: dispatch-ledger.sh <plan|inc|excuse|done|check|report|status> <role> ...}"
ROLE="${2:?missing role}"
shift 2 || true
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LEDGER="$ROOT/locks/dispatch-$ROLE.tsv"
mkdir -p "$ROOT/locks"

case "$CMD" in
  plan)
    [ $# -ge 1 ] || { echo "plan needs at least one unit" >&2; exit 2; }
    : > "$LEDGER"
    for u in "$@"; do printf '%s\tplanned\t-\t%s\n' "$u" "$(date +%H%M%S)" >> "$LEDGER"; done
    echo "planned $# unit(s) for $ROLE"
    ;;
  inc)
    u="${1:-auto}"
    if grep -q "^$u	planned	-	" "$LEDGER" 2>/dev/null; then
      sed -i "s/^$u	planned	-	/$u	dispatched	-	/" "$LEDGER"
    else
      printf '%s\tdispatched\t-\t%s\n' "$u" "$(date +%H%M%S)" >> "$LEDGER"
    fi
    echo "dispatched $u"
    ;;
  excuse)
    u="${1:?missing unit}"; code="${2:?missing code}"
    case "$code" in dep|files|build|order|device|rea|atomic) ;; *) echo "bad code: $code" >&2; exit 2 ;; esac
    if grep -q "^$u	planned	-	" "$LEDGER" 2>/dev/null; then
      sed -i "s/^$u	planned	-	/$u	excused	$code	/" "$LEDGER"
    else
      printf '%s\texcused\t%s\t%s\n' "$u" "$code" "$(date +%H%M%S)" >> "$LEDGER"
    fi
    echo "excused $u ($code)"
    ;;
  done)
    u="${1:?missing unit}"
    sed -i "s/^$u	dispatched	/$u	done	-	/" "$LEDGER" 2>/dev/null || true
    echo "done $u"
    ;;
  check)
    [ -f "$LEDGER" ] || exit 0
    left="$(awk -F'\t' '$2=="planned"{printf "%s ", $1}' "$LEDGER")"
    [ -n "$left" ] || exit 0
    n="$(awk -F'\t' 'END{print NR}' "$LEDGER")"
    d="$(awk -F'\t' '$2!="planned"{c++} END{print c+0}' "$LEDGER")"
    echo "[dispatch] units $n -> dispatched/excused $d, still undispatched: $left" >&2
    echo "[dispatch] dispatch first: send the remaining units, or record a reason with excuse (dep|files|build|order|device|rea|atomic). See team.md §5.2." >&2
    exit 2
    ;;
  report)
    n="$(awk -F'\t' 'END{print NR}' "$LEDGER" 2>/dev/null || echo 0)"
    units="$(awk -F'\t' '{printf "%s ", $1}' "$LEDGER" 2>/dev/null)"
    m="$(awk -F'\t' '$2=="dispatched"||$2=="done"{c++} END{print c+0}' "$LEDGER" 2>/dev/null)"
    k="$(awk -F'\t' '$2=="excused"{c++} END{print c+0}' "$LEDGER" 2>/dev/null)"
    codes="$(awk -F'\t' '$2=="excused"{printf "%s:%s ", $1, $3}' "$LEDGER" 2>/dev/null)"
    echo "concurrency: units $n ($units) -> dispatched $m + not dispatched $k (${codes:-none})"
    ;;
  status)
    if [ -f "$LEDGER" ]; then column -t -s "$(printf '\t')" "$LEDGER"; else echo "(no ledger for $ROLE)"; fi
    ;;
  *) echo "unknown cmd: $CMD" >&2; exit 2 ;;
esac
