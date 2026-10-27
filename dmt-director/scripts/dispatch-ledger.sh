#!/usr/bin/env bash
# =============================================================================
# dispatch-ledger.sh -- thin shell over the max-subagents ledger kernel (ledger.py)
# =============================================================================
# [Current state of this file]
#   This script has converged from "self-implemented ledger read/write/stats/lock" into a **thin shell over max-subagents/ledger.py**:
#   every ledger criterion (pending/inflight counting, duplicate-unit rejection, stale-lock takeover, subagent-context
#   detection, expiry criterion, dispatch tool allowlist) is delegated to one single implementation:
#     /home/panxiaoyong/pxy/projects26h2/max-subagents/ledger.py (+ policy.py)
#   The historical implementation is kept as-is as a backup in the same directory: scripts/dispatch-ledger.sh.orig-20261027 (152 lines).
#
# [Where the 7 defects are fixed] (details in max-subagents/docs/ledger-design.md §4, docs/ledger.md §5)
#   1. report over-counts (counting excused as undispatched): pending counts planned only.
#      -> policy.counts_from_rows(); this shell's report pulls the numbers with query --json and then formats them the dmt way.
#   2. plan does not deduplicate -> ghost units: a duplicate unit is rc=2 and writes nothing.
#      -> ledger.py cmd_plan(); this shell passes --reset to plan (dmt's plan is by definition a reset).
#   3. Locks have no stale reclamation (a leftover lock -> 11s/rc=4, the role is paralyzed forever): the lock stores pid+ts;
#      a dead pid / age > 10s is taken over immediately, the wait cap is 3s, and a timeout fails open to rc=0.
#      -> ledger.py LedgerLock; this shell [removes] the old mkdir lock logic and no longer carries its own lock.
#   4. Timestamps had no date and expiry used the file mtime: row timestamps are now ISO with a date; expiry uses the row time.
#      -> policy.now_iso() / ledger.py _effective_rows(); this shell passes
#      MAX_SUBAGENTS_LEDGER_TTL_HOURS=24 for check (old ledgers do not block) and never looks at the file mtime.
#   5. inc did not distinguish subagent context: when the payload carries an agent_id the parent ledger is not closed.
#      -> policy.is_subagent() / ledger.py cmd_inc().
#   6. The dispatch tool-name allowlist diverged from the gate: unified in policy.SPAWN_RE.
#      -> policy.SPAWN_RE / ledger.py cmd_inc().
#   7. The pi adapter does not pass agent_id (a new finding on the max-subagents side): see the adapter docs, unrelated to this shell.
#
# [External contract (used by dmt hooks and humans, unchanged)]
#   Subcommands: plan / inc / excuse / done / check / report / status / ledger-path / inject / nudge
#   Invocation: bash dispatch-ledger.sh <cmd> <role> [args...]; inc/check/nudge read the payload from stdin
#   Role: dmt_role ("-"/empty -> DMT_ROLE -> herdr pane label); only
#     director|devm|anam|director-helper|devm-helper|anam-helper are governed, other roles silently exit 0;
#     DMT_DISPATCH_ALL=1 bypasses the allowlist
#   Ledger: $(dmt_root)/locks/dispatch-<ROLE>.tsv (keeping the original layout, not moved to a state directory)
#   excuse reason codes: dep|files|build|order|device|rea
#   check: units undispatched and 0 in flight -> rc=2; stop_hook_active=true -> rc=0; a >24h old ledger does not block
#   report: the concurrency ledger line: units N (units) -> dispatched M + not dispatched K (reason) [CAP=cap] (CAP comes from probe-cap.sh)
#   nudge: hookSpecificOutput.additionalContext JSON
#   inject: dmt's original wording
#
# [fail-open]
#   Kernel unavailable / unexpected exit code (other than 0/2): check is always rc=0 (never wedge an agent);
#   other commands print an error to stderr and then rc=0. A script failure must never wedge a dmt agent.
# =============================================================================
set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib-dmt.sh"

# Ledger kernel: an absolute-path constant (relative paths are forbidden -- cwd is not controlled and a relative path would miss)
KERNEL="/home/panxiaoyong/pxy/projects26h2/max-subagents/ledger.py"

CMD="${1:?usage: dispatch-ledger.sh <plan|inc|excuse|done|check|report|status|ledger-path|inject|nudge> <role> ...}"
ROLE="${2:?missing role}"
shift 2 || true

# Role resolution: argument "-" or empty => $DMT_ROLE => herdr pane label; only director/devm/anam and helpers are governed
ROLE="$(dmt_role "$ROLE")"
if [ "${DMT_DISPATCH_ALL:-0}" != 1 ]; then
  case "$ROLE" in
    director|devm|anam|director-helper|devm-helper|anam-helper) ;;
    *) exit 0 ;;   # an ungoverned role silently exits 0 for every command (contract 10)
  esac
fi
# Empty-role fallback: it must not enter a file path / lock name (referencing an undefined variable requires a default, contract 2)
[ -n "$ROLE" ] || ROLE="default"

# The ledger always lands at the *main worktree* root: running inside a worktree still writes <main>/locks/ (contract 4)
ROOT="$(dmt_root)"
LEDGER="$ROOT/locks/dispatch-$ROLE.tsv"
mkdir -p "$ROOT/locks" 2>/dev/null || true

# hook payload: read stdin when not a tty (forwarded as-is to the kernel; a 1s timeout prevents a hang)
payload=""
if [ ! -t 0 ]; then payload="$(timeout 1 cat 2>/dev/null || true)"; fi

# Whether the kernel is available (a missing script / no python3 both count as unavailable -> fail-open)
kernel_available() {
  [ -f "$KERNEL" ] && command -v python3 >/dev/null 2>&1
}

# Pass-through execution: stdin=payload; exit codes 0/2 are returned as-is (contract semantics), anything else
# (including a missing kernel) prints an error and returns rc=0.
# One invocation calls the kernel exactly once => no read-modify-write race (the lock is managed inside ledger.py).
kernel_pass() {
  local rc=0
  if ! kernel_available; then
    echo "[dispatch] ledger kernel unavailable ($KERNEL), fail-open: rc=0" >&2
    return 0
  fi
  printf '%s' "$payload" | python3 "$KERNEL" "$@" || rc=$?
  case "$rc" in
    0|2) return "$rc" ;;
    *) echo "[dispatch] ledger kernel ${1:-} exited unexpectedly with $rc, fail-open to rc=0" >&2; return 0 ;;
  esac
}

case "$CMD" in
  plan)
    # Contract 3: a duplicate unit is rejected rc=2 and writes nothing (ledger.py checks duplicates before writing)
    [ "$#" -ge 1 ] || { echo "plan needs at least one unit" >&2; exit 2; }
    rc=0
    kernel_pass plan --ledger-path "$LEDGER" --session "$ROLE" --reset -- "$@" || rc=$?
    exit "$rc"
    ;;
  inc)
    # Automatic hook bookkeeping looks like `inc - auto`: auto/-/empty all omit --unit, and the kernel claims the first planned one
    args=(inc --ledger-path "$LEDGER" --session "$ROLE")
    case "${1:-}" in
      ""|auto|-) ;;
      *) args+=(--unit "$1") ;;
    esac
    rc=0
    kernel_pass "${args[@]}" || rc=$?
    exit "$rc"
    ;;
  excuse)
    [ "$#" -ge 1 ] || { echo "excuse needs a unit" >&2; exit 2; }
    [ "$#" -ge 2 ] || { echo "excuse needs a code" >&2; exit 2; }
    rc=0
    kernel_pass excuse --ledger-path "$LEDGER" --session "$ROLE" --unit "$1" --code "$2" || rc=$?
    exit "$rc"
    ;;
  done)
    [ "$#" -ge 1 ] || { echo "done needs a unit" >&2; exit 2; }
    rc=0
    kernel_pass done --ledger-path "$LEDGER" --session "$ROLE" --unit "$1" || rc=$?
    exit "$rc"
    ;;
  check)
    # Contract 6: a >24h old ledger does not block -- expiry is judged by the in-row ISO time (the kernel supports it), never by the file mtime
    export MAX_SUBAGENTS_LEDGER_TTL_HOURS="${MAX_SUBAGENTS_LEDGER_TTL_HOURS:-24}"
    rc=0
    kernel_pass check --ledger-path "$LEDGER" --session "$ROLE" || rc=$?
    exit "$rc"
    ;;
  report)
    # Contract 7: pull the kernel stats (including rows) and format them the dmt way + CAP
    cap="$(bash "$DIR/probe-cap.sh" 2>/dev/null || echo 8)"
    json=""
    if kernel_available; then
      json="$(python3 "$KERNEL" query --ledger-path "$LEDGER" --session "$ROLE" --json 2>/dev/null || true)"
    fi
    total=0; pending=0; inflight=0; done_n=0; units=""; codes=""
    if [ -n "$json" ] && command -v jq >/dev/null 2>&1; then
      total="$(printf '%s' "$json" | jq -r '.total // 0' 2>/dev/null || echo 0)"
      pending="$(printf '%s' "$json" | jq -r '.pending // 0' 2>/dev/null || echo 0)"
      inflight="$(printf '%s' "$json" | jq -r '.inflight // 0' 2>/dev/null || echo 0)"
      done_n="$(printf '%s' "$json" | jq -r '.done // 0' 2>/dev/null || echo 0)"
      units="$(printf '%s' "$json" | jq -r '[.rows[]?.unit] | join(" ")' 2>/dev/null || true)"
      codes="$(printf '%s' "$json" | jq -r '[.rows[]? | select(.status=="excused") | "\(.unit):\(.code) "] | join("")' 2>/dev/null || true)"
    fi
    # Numeric fallbacks: a jq failure must not break the arithmetic (fail-open)
    case "$total" in ''|*[!0-9]*) total=0 ;; esac
    case "$pending" in ''|*[!0-9]*) pending=0 ;; esac
    case "$inflight" in ''|*[!0-9]*) inflight=0 ;; esac
    case "$done_n" in ''|*[!0-9]*) done_n=0 ;; esac
    case "$cap" in ''|*[!0-9]*) cap=8 ;; esac
    m=$(( inflight + done_n ))     # "dispatched" = in flight + done (matching the original format)
    k="$pending"                   # "not dispatched" = planned only (defect 1 fix: excused is no longer counted in)
    extra=""
    if [ "$k" -gt 0 ] && [ "$inflight" -ge "$cap" ]; then extra="cap: in-flight at the limit, batch and queue "; fi
    reason="${codes}${extra}"
    if [ -z "$reason" ] && [ "$k" -gt 0 ]; then reason="missing reason code (non-compliant: must dispatch or excuse)"; fi
    echo "concurrency ledger: units $total ($units) -> dispatched $m + not dispatched $k (${reason:-none}) [CAP=$cap]"
    exit 0
    ;;
  status)
    rc=0
    kernel_pass status --ledger-path "$LEDGER" --session "$ROLE" || rc=$?
    exit "$rc"
    ;;
  ledger-path)
    # Used by parallel-guard.sh / self-work-guard.sh; prints the resolved absolute path (contract 4)
    out=""
    if kernel_available; then
      out="$(python3 "$KERNEL" ledger-path --ledger-path "$LEDGER" 2>/dev/null || true)"
    fi
    printf '%s\n' "${out:-$LEDGER}"
    exit 0
    ;;
  inject)
    # Contract 9: keep dmt's original wording (including CAP and the team.md rule)
    cap="$(bash "$DIR/probe-cap.sh" 2>/dev/null || echo 8)"
    echo "Parallel discipline (dmt): dispatch dependency-free units as min(N, CAP) sub-agents concurrently (open on demand, capped at min(8, cap); when N exceeds the cap, batch it; current CAP=$cap, probed by probe-cap.sh; top up the dispatch before closing out after a wake-up); dispatch first -- list the units and book them with dispatch-ledger.sh plan before touching the work; sub-agents always use run_in_background: true; report to your superior as soon as you close out (report on completion, do not wait idly)."
    exit 0
    ;;
  nudge)
    # Contract 8: the kernel output is exactly the hookSpecificOutput.additionalContext JSON
    rc=0
    kernel_pass nudge --ledger-path "$LEDGER" --session "$ROLE" || rc=$?
    exit "$rc"
    ;;
  *)
    echo "unknown cmd: $CMD" >&2
    exit 2
    ;;
esac
