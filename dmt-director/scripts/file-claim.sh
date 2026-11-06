#!/usr/bin/env bash
# dmt 文件占用登记（编辑前检查，避免并发写同一文件）
# 模型参考 Orca：先看有没有活跃 agent 在同一 worktree，再登记本文件的占用。
# 用法：
#   bash file-claim.sh check   <path> [owner]
#   bash file-claim.sh claim   <path> <owner>
#   bash file-claim.sh release <path> <owner>
#   bash file-claim.sh list
# 返回码：0 可写/成功；3 被他人占用；2 用法错误
# 环境变量：DMT_LOCKS_DIR（默认 <项目根>/locks）、DMT_CLAIM_TTL（秒，默认 1800）
set -u

# 锁登记固定落在「主工作树」根：worktree 里跑也写回 <main>/locks/，
# 否则 director 在项目根巡检 locks/ 看不到，且各分支 .gitignore 未必有 locks/。
DIR="$(cd -P "$(dirname "$0")" && pwd -P)"
. "$DIR/lib-dmt.sh"
ROOT="$(dmt_root)"
LOCKS="${DMT_LOCKS_DIR:-$ROOT/locks}"
TTL="${DMT_CLAIM_TTL:-1800}"
mkdir -p "$LOCKS" 2>/dev/null

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

cmd="${1:-}"; target="${2:-}"; owner="${3:-}"
if [ "$cmd" != "list" ]; then
  [ -n "$cmd" ] && [ -n "$target" ] || usage
fi

# 规范化成相对项目根的路径（不存在的文件也能算；list 不需要 target）
rel=""; lock=""
if [ -n "$target" ]; then
  abs="$(realpath -m "$target")"
  rel="${abs#"$ROOT"/}"
  [ "$rel" = "$abs" ] && rel="$(basename "$abs")"
  key="$(printf '%s' "$rel" | sha1sum | cut -c1-16)"
  lock="$LOCKS/$key.lock"
fi

now() { date +%s; }
read_ts() { [ -f "$1/ts" ] && cat "$1/ts" || echo 0; }
read_owner() { [ -f "$1/owner" ] && cat "$1/owner" || echo "?"; }
expired() { [ $(( $(now) - $(read_ts "$1") )) -gt "$TTL" ]; }

case "$cmd" in
  check)
    if [ ! -d "$lock" ]; then
      echo "FREE  $rel"
      exit 0
    fi
    o="$(read_owner "$lock")"
    if expired "$lock"; then
      echo "STALE $rel（原持有者 $o，已超 ${TTL}s）——可抢占，抢占时须在回报里写明"
      exit 0
    fi
    if [ -n "$owner" ] && [ "$o" = "$owner" ]; then
      echo "MINE  $rel（$o）"
      exit 0
    fi
    echo "BUSY  $rel 正被 $o 占用（$(( $(now) - $(read_ts "$lock") ))s）"
    exit 3
    ;;

  claim)
    [ -n "$owner" ] || usage
    if mkdir "$lock" 2>/dev/null; then
      printf '%s' "$rel"   > "$lock/path"
      printf '%s' "$owner" > "$lock/owner"
      now                  > "$lock/ts"
      echo "CLAIMED $rel by $owner"
      exit 0
    fi
    o="$(read_owner "$lock")"
    if [ "$o" = "$owner" ]; then
      now > "$lock/ts"
      echo "RENEWED $rel by $owner"
      exit 0
    fi
    if expired "$lock"; then
      rm -rf "$lock"
      if mkdir "$lock" 2>/dev/null; then
        printf '%s' "$rel"   > "$lock/path"
        printf '%s' "$owner" > "$lock/owner"
        now                  > "$lock/ts"
        echo "CLAIMED $rel by $owner（接管过期锁，原持有者 $o）"
        exit 0
      fi
    fi
    echo "BUSY  $rel 正被 $o 占用（$(( $(now) - $(read_ts "$lock") ))s）"
    exit 3
    ;;

  release)
    [ -n "$owner" ] || usage
    if [ ! -d "$lock" ]; then
      echo "FREE  $rel（无占用）"
      exit 0
    fi
    o="$(read_owner "$lock")"
    if [ "$o" != "$owner" ]; then
      echo "BUSY  $rel 由 $o 持有，$owner 不得释放"
      exit 3
    fi
    rm -rf "$lock"
    echo "RELEASED $rel by $owner"
    exit 0
    ;;

  list)
    found=0
    for d in "$LOCKS"/*.lock; do
      [ -d "$d" ] || continue
      found=1
      p="$(cat "$d/path" 2>/dev/null || echo '?')"
      o="$(read_owner "$d")"
      age=$(( $(now) - $(read_ts "$d") ))
      st="active"; expired "$d" && st="stale"
      echo "$st  $p  owner=$o  age=${age}s"
    done
    [ "$found" -eq 1 ] || echo "（无占用）"
    exit 0
    ;;

  *) usage ;;
esac
