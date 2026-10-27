#!/usr/bin/env bash
# Install dmt's dispatch hard rules as CodeBuddy hooks
# Usage:
#   bash install-hooks.sh <project-root>     install into <project>/.codebuddy/settings.json (scripts from <project>/dmt-director/scripts)
#   bash install-hooks.sh --user             install into ~/.codebuddy/settings.json (scripts from this repo; all dispatch roles machine-wide)
#   --dry-run only print the target path
# Governed roles: director / devm / anam and helpers (DMT_DISPATCH_ALL=1 widens it to other roles)
set -eu
ARG1="${1:?usage: install-hooks.sh <project-root>|--user [--dry-run]}"
DRY=0; [ "${2:-}" = "--dry-run" ] && DRY=1
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$ARG1" = "--user" ]; then
  CFG="$HOME/.codebuddy/settings.json"
  DIR="$SELF_DIR"
else
  ROOT="$(cd "$ARG1" && pwd)"
  DIR="$ROOT/dmt-director/scripts"
  [ -d "$DIR" ] || { echo "missing $DIR (run install-skills.sh first)" >&2; exit 2; }
  CFG="$ROOT/.codebuddy/settings.json"
fi
if [ "$DRY" = 1 ]; then echo "would write $CFG (scripts: $DIR)"; exit 0; fi
mkdir -p "$(dirname "$CFG")"
# a copied script tree loses the executable bit; the hook runs via `bash` but 4j checks -x
chmod +x "$DIR"/*.sh 2>/dev/null || true
# Always overwrite a single .bak (the old version kept a timestamped copy on every install, piling up forever)
[ -f "$CFG" ] && cp "$CFG" "$CFG.bak"

python3 - "$CFG" "$DIR" <<'PY'
import json, os, sys
cfg, d = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(cfg):
    try: data = json.load(open(cfg, encoding="utf-8"))
    except Exception: data = {}
hooks = data.setdefault("hooks", {})
def is_dmt(cmd):
    return ("dispatch-ledger.sh" in cmd) or ("self-work-guard.sh" in cmd) or ("parallel-guard.sh" in cmd)
# drop previous dmt entries so a matcher change cannot leave a duplicate behind
for ev in list(hooks):
    kept = []
    for item in hooks[ev]:
        item["hooks"] = [h for h in item.get("hooks", []) if not is_dmt(h.get("command", ""))]
        if item["hooks"]: kept.append(item)
    hooks[ev] = kept
def add(event, matcher, cmd):
    entry = {"hooks": [{"type": "command", "command": cmd}]}
    if matcher: entry["matcher"] = matcher
    hooks.setdefault(event, []).append(entry)
# matcher "*" everywhere: the scripts filter by tool_name / file path themselves
add("PostToolUse", "*", "bash " + d + "/dispatch-ledger.sh inc - auto")
add("PostToolUse", "*", "bash " + d + "/dispatch-ledger.sh nudge -")
add("Stop", None, "bash " + d + "/dispatch-ledger.sh check -")
add("PreToolUse", "*", "bash " + d + "/self-work-guard.sh -")
add("PreToolUse", "*", "bash " + d + "/parallel-guard.sh -")
add("SessionStart", None, "bash " + d + "/dispatch-ledger.sh inject -")
json.dump(data, open(cfg, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("hooks written to", cfg)
PY
echo "roles governed: director|devm|anam|director-helper|devm-helper|anam-helper (override with DMT_DISPATCH_ALL=1)"
echo "role is resolved from DMT_ROLE or the herdr pane label; ungoverned sessions exit 0 immediately"
