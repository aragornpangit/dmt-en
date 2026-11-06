# Per-harness improvement list (BACKLOG)

> **Chinese source**: see [`../../logs/2026-11-06-harness-test-report.md`](../../logs/2026-11-06-harness-test-report.md).
> Source: end-to-end testing of five harnesses ([`../../logs/2026-11-06-harness-test-report.md`](../../logs/2026-11-06-harness-test-report.md)).
> Status: `DONE` = improvement landed in the repo; `WATCH` = environment-side / upstream-side issue, the repo can only provide a fallback and record it; `OPEN` = to do.
> **Discipline**: every item must state a "criterion" (how to verify the fix is good); "fixed, therefore done" is not accepted.

## pi

| # | Item | Criterion | Status |
|---|---|---|---|
| P1 | Subagent has no skill list (`delegate` `inheritSkills: false`) | For a custom agent with `inheritSkills: false + skills:[…]`, the subagent's `<available_skills>` contains **only the listed skills** | **DONE** (`harness/pi-agents/`; observed in test: only `dmt-de/tdd/code-review/diagnosing-bugs`) |
| P2 | No Skill tool (forwarding-style skills silently fail) | `harness/pi.md` §5.1 lists the degraded reading approach for `grill-with-docs`/`grill-me`/`implement`/`tdd` | **DONE** |
| P3 | Concurrency cap undeclared (matrix `null`) | `harness_matrix.yaml` has a value for `pi.max_subagents_conc`, consistent with pi-subagents defaults (`maxTasks=8` / `concurrency=4`) | **DONE** (filled in 8 plus a note on the config key) |
| P4 | Same-name skills registered twice (`tdd`/`code-review` twice each) | `harness/pi.md` §4.4 states the cause and the avoidance (name them via `skills:`; keep only one copy) | **DONE** |
| P5 | Input not ready early after startup (`/skill:` arrives before the TUI is ready) | After load, `dmt_confirm_role_ready` must re-check that "role name + one-time credential" appears in the pane output | **DONE** (`harness/pi.md` §7 + the function already exists in `lib-dmt.sh`) |

## codebuddy (cbc)

| # | Item | Criterion | Status |
|---|---|---|---|
| C1 | Risk of mixing `-y` with `--permission-mode auto` (the former still asks on HIGH/CRITICAL) | `harness/codebuddy.md` §2 states the difference between the two levels and the criterion | **DONE** |
| C2 | Subagent permission inheritance not explicitly specified | Matrix codebuddy `start_cmd` carries `--subagent-permission-mode bypassPermissions`, so subagents no longer fall back to the default level | **DONE** |
| C3 | In auto mode, the reviewer rate limit disguised "command failed" as a script fault | `ops/permission-notes.md` now carries the 300s budget + health gate + allow rules; `harness/codebuddy.md` points to it | **DONE** (pre-existing) |
| C4 | When the `cbc-herdr` registration is missing, `agent_status` stays `unknown` | After the three pane roles start, `agent_status != unknown`; if missing, add the registration per `harness/codebuddy.md` §6 | **DONE** (pre-existing docs) |

## claude

| # | Item | Criterion | Status |
|---|---|---|---|
| L1 | In `auto` mode, the remote classifier rate limit (9 of 122 Bash calls rejected) | `harness/claude.md` §2 states: no local reviewer, the yolo level may be used instead | **DONE** |
| L2 | With `permissions.defaultMode=auto`, argv carries no level ⇒ `dmt_pane_auto_mode` false positive | `harness/claude.md` §2 records it as a "known false-positive surface + manual confirmation" | **DONE** |
| L3 | Duplicate user-level and project-level installs (the old copy gets picked up by non-dmt projects) | `harness/claude.md` §6 states the recommendation (keep only the project-level copy, or symlink to the repo); the machine check does not enforce it | **DONE** (documentation level) |
| L4 | Env var name for the concurrency cap | Matrix `claude.max_subagents_env = CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` | **DONE** |

## codex

| # | Item | Criterion | Status |
|---|---|---|---|
| X1 | Default sandbox refuses the herdr socket ⇒ doorbell/identity/file-claim all broken | Matrix `start_cmd = codex -a never --sandbox danger-full-access`; `cd <project> && send-msg.sh …` produces no `WARN` | **DONE** |
| X2 | Shell reuses a stale persistent environment (`HERDR_*` pointing at an abandoned session) | Simulate a stale environment (`HERDR_SESSION=bcr-nihui` etc.) and run `send-msg.sh`: `rc=0` and no `WARN` | **DONE** (`dmt_herdr_env_fix`) |
| X3 | `spawn_agent` payload is not delivered (retested under Full Access, same failure) | Can only be re-judged after an upstream codex fix; for now record it as `[SUBAGENT_UNAVAILABLE]` and have this pane act in its place | **WATCH** (upstream defect, retest evidence attached) |
| X4 | Skill injection depends on the first-turn prompt (`first_prompt: true`) | `harness/codex.md` §4 states "skills and task are delivered with the first turn; reloading requires reopening the pane" | **DONE** |
| X5 | If subagents are available, nesting must be limited | `harness/codex.md` §4 already states "when there is no spawn_agent interface, do not fake a team via nested shells" | **DONE** |

## opencode

| # | Item | Criterion | Status |
|---|---|---|---|
| O1 | Slash command list incomplete (`/to-spec`, `/to-tickets` typed but ineffective) | `harness/opencode.md` §3 changed to "prefer the `skill` tool (load by id); fall back to reading the file directly when unavailable" | **DONE** |
| O2 | Input not ready early after startup (`agent prompt` only fills in, does not submit) | Docs state "after the first injection, re-check the pane output and add `send-keys enter` if needed" | **DONE** |
| O3 | Concurrency cap undeclared | Matrix `opencode.max_subagents_conc` notes "no upstream entry point; judge by task scale" | **DONE** (explicitly declared as not set rather than left blank) |
| O4 | Skill discovery directories trip on singular/plural (`.opencode/skills/` vs `skill/`) | `harness/opencode.md` §1 already states the singular form does not take effect | **DONE** |

## Cross-harness

| # | Item | Criterion | Status |
|---|---|---|---|
| A1 | A skill "can load" ≠ "can work" (forwarding-style skills) | `harness/COMMON.md` §2 points to §1.4; `pi.md` §5.1 gives the degraded-mode rules | **DONE** |
| A2 | Pane communication is the common baseline, but codex is the exception | The matrix already builds in codex's full-access; `harness/codex.md` §6.1 comparison table | **DONE** |
| A3 | Subagent boundaries (artifact boundaries / loaded ≠ started) | `harness/COMMON.md` §7 | **DONE** |
| A4 | The machine check must be able to catch regressions | `check-dmt.sh` A6b: harness files complete + consistent with matrix keys + seven skills include step 0 + detection script self-test for five harnesses + pi-agents allowlist shape | **DONE** |
