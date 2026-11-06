# Harness × dmt Test Report (English summary)

> Companion to the Chinese report [`2026-11-06-harness-test-report.md`](2026-11-06-harness-test-report.md)
> and the improvement backlog [`../dmt-director/harness/BACKLOG.md`](../dmt-director/harness/BACKLOG.md).

## Scope

End-to-end validation of the seven dmt role skills on five agent harnesses —
**pi (pi-coding-agent), codebuddy (cbc), claude (Claude Code), codex (Codex CLI), opencode** —
covering skill discovery → loading → mandatory-skill invocation → subagent delegation → pane doorbell.

Every result is backed by a re-runnable artifact (script output, session-file parse, file path), never by model self-report.

## Method (identical for all five)

| Step | Detail |
|---|---|
| Project | `/tmp/dmt-<harness>-lab` installed with `install-skills.sh --harness <h>`; repo check must be `ALL_PASS` |
| Panes | Contract names `director` / `devm` / `anam` (also exercises `dmt_pane_by_label` exact lookup) |
| Launch | Each harness's yolo/auto mode (see table) |
| Loading | `herdr agent prompt <pane> /dmt-<role>` (`/skill:` on pi) |
| Tests | T1 load · T2 `to-spec`+`to-tickets` · T3 `implement`→`tdd`→`code-review` · T4 `research`+parallel subagents · T5 doorbell |

## Results

| | pi | cbc | claude | codex | opencode |
|---|---|---|---|---|---|
| Version | 1.5.0 | 2.180.0 | 2.1.318 | 0.166.0 | 2.2.5 |
| Launch | `--approve` | `-y` | `--dangerously-skip-permissions` | `-a never` + **must** `--sandbox danger-full-access` | `--auto` |
| T1 load | ✅ | ✅ | ✅ | ✅ | ✅ |
| T2 SPEC+tickets | ✅ | ✅ | ✅ | ✅ | ✅ |
| T3 implement chain | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| T4 research + subagents | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| T5 doorbell | ✅ | ✅ | ✅ | ⚠️→✅ | ✅ |
| Skill tool | ❌ | ✅ | ✅ | ❌ | ✅ |
| Subagent carrier | `delegate` + agent allowlist | `Agent` | `Agent` | `spawn_agent` (**payload lost**) | `subagent` |

## Per-harness findings and fixes

### pi — degraded carrier, completed with custom agents

- **No Skill tool**: the model can only read `SKILL.md`. Three ways in: `/skill:<name>`, `--skill <dir>`, or an `<available_skills>` catalog.
- **Subagents do not inherit skills**: builtin `delegate` is `inheritSkills: false` (verified: no `<available_skills>` section).
- **Measured granularity**: `delegate` → none; `inheritSkills: false + skills: [dmt-pde]` → exactly `dmt-pde`; `inheritSkills: true` → full catalog (`skills` does not prune).
- **Fix shipped**: `harness/pi-agents/` provides four allowlisted agent definitions (`dmt-dev-e`, `dmt-ana-e`, `dmt-pde`, `dmt-reviewer`), installed to `<target>/.pi/agents/`; plus `--skill` / `--approve` launch paths and the "forwarding skill" downgrade rule (§5.1).
- **Also fixed**: `max_subagents_conc` `null` → `8` (pi-subagents defaults `maxTasks=8` / `concurrency=4`).

### codebuddy (cbc) — works out of the box

- All five tests pass; `Skill` tool even invokes `disable-model-invocation: true` skills.
- **Two auto modes must not be mixed**: `-y` skips the reviewer but still asks for HIGH/CRITICAL; `--permission-mode auto` sends every tool call through the auto-reviewer (300 s budget + health gate).
- **Fix shipped**: `--subagent-permission-mode bypassPermissions` added to the launch command so teammates do not fall back to `default` and hit per-call approvals.

### claude — works natively

- All five tests pass; 4–6 real `Skill` calls per role and 4 `Agent` subagents observed.
- **No local reviewer**: the codebuddy hardening does not apply. `auto` mode depends on a remote classifier and was rate-limited 9 times out of 122 Bash calls (symptom: command failure, root cause in the permission layer).
- **Known false negative**: with user-level `permissions.defaultMode=auto`, argv carries no mode flag, so `dmt_pane_auto_mode` (argv-based) misreports.
- **Duplicate installs**: user-level `~/.claude/skills/dmt-*` and project-level copies both exist.

### codex — the only harness needing a sandbox change

- **Sandbox**: the default `workspace-write` sandbox refuses the herdr unix socket (`PermissionDenied: Operation not permitted`), killing the doorbell, identity self-check and file-claim. With `--sandbox danger-full-access` the doorbell is delivered and acknowledged.
- **Stale shell environment**: the codex process `environ` is correct (`w9`/`bcr-nh`), but its `exec_command` (`bash -lc`) reports an obsolete session (`w1`/`bcr-nihui`); prefixing `env HERDR_…=correct codex` does not help.
  - **Fix shipped**: `lib-dmt.sh: dmt_herdr_env_fix [label]` scans `sessions/*/herdr.sock` and adopts the unique match on "target label + `cwd==$PWD`", exporting the corrected environment in the parent shell. Verified: simulated stale environment → `rc=0`, no `WARN`.
- **`spawn_agent` payload is never delivered**: the tool is genuinely called (1/2/2 times per role) but subagents receive an empty task; **re-tested under Full Access with the same failure** ⇒ upstream defect, recorded as `[SUBAGENT_UNAVAILABLE]` (the pane does the work itself).

### opencode — works, with two quirks

- All five tests pass (`skill` tool 1/4/2 calls, `subagent` ×2, `pytest` 2 passed).
- **Slash list is incomplete**: `/to-spec` and `/to-tickets` are not registered, but the `skill` tool loads them by id (including `disable-model-invocation: true` ones) ⇒ rule changed to "skill tool first, fall back to reading the file".
- **First prompt may not submit**: right after startup, `agent prompt` only fills the input box; re-check the pane output (or send an extra `enter`).
- Concurrency: upstream provides no entry point ⇒ explicitly recorded as unset, not forgotten.

## Cross-cutting conclusions

1. **Native vs degraded carriers**: claude / cbc / opencode expose a Skill tool and let subagents inherit skills; pi and codex do not — pi is compensated by agent allowlists, codex has an upstream subagent defect.
2. **Pane communication is the common floor**: `herdr agent prompt` works on all five, but codex's default sandbox is the sole exception — hence it is now baked into the matrix default.
3. **"Skill loads" ≠ "skill works"**: forwarding skills (`grill-with-docs`, `grill-me`, `implement`, `tdd`) depend on the Skill tool and must be downgraded to file reads where it is missing.

## Reproduce

```bash
bash dmt-director/scripts/install-skills.sh /tmp/lab --harness pi
DMT_SKILLS_DIR=/tmp/lab/.agents/skills bash /tmp/lab/dmt-director/scripts/check-dmt.sh /tmp/lab
bash dmt-director/scripts/harness-detect.sh --explain
cd /tmp/lab && bash dmt-director/scripts/send-msg.sh director devm probe /tmp/body.md
```
