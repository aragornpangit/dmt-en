# harness differences: codebuddy (CodeBuddy Code / cbc)

> For the shared parts see [`COMMON.md`](COMMON.md); the single source of machine-readable facts is [`../harness_matrix.yaml`](../harness_matrix.yaml).

## 1. Skill discovery directories

| Level | Directories |
|---|---|
| Project level | `.codebuddy/skills/` |
| User level | `~/.codebuddy/skills/` |

It does **not read** `.agents/skills/` ⇒ to install for cbc you must symlink into `.codebuddy/skills/` (`install-skills.sh --harness all` already covers all three locations).

## 2. Startup and permissions

- On-behalf startup: run the health gate `auto-review-model.sh --quiet` first, then `CODEBUDDY_AUTO_REVIEW_TIMEOUT_MS=300000 codebuddy --permission-mode auto`.
- There are two auto modes; **do not mix them** (measured 2026-11-05):
  - `--permission-mode auto`: every tool call that needs approval goes through the auto reviewer (with a 300s budget paired with the health gate, see below).
  - `-y` / `--dangerously-skip-permissions`: **skips the reviewer**, but `--help` states explicitly that **HIGH/CRITICAL risk operations still prompt** (this is not a full exemption).
  - Both checks read argv (`dmt_pane_auto_mode` recognizes `--permission-mode auto` and `--dangerously-skip-permissions`).
- In auto mode **every tool call that needs approval must pass the reviewer once** ⇒ for budget and allow rules see [`../ops/permission-notes.md`](../ops/permission-notes.md).

## 3. Skill invocation line

`/<skill name>`, e.g. `/dmt-dm`.

## 4. How skills reach the model

- Teammates **inherit the skill list** ⇒ they can invoke `/dmt-de` etc. directly; **no** need to read file paths.
- Subagents: `Agent({ name: "<role name>" })` — the role name is used directly as `name`, and skills come along by inheritance (for the template see [`../team/07b-dispatch.md`](../team/07b-dispatch.md)).

## 5. Mandatory skills

`/<name>` (e.g. `/code-review`).

## 5.1 Subagent permission inheritance (added from measurements on 2026-11-06)

- The matrix `start_cmd` already carries **`--subagent-permission-mode bypassPermissions`**: otherwise teammates / subagents may fall back to the `default` level and hit approvals command by command (the symptom is "subagent hangs / script times out", while the root cause is the permission layer).
- If a session is started manually (not via `setup-team.sh`), add this parameter yourself, or confirm that the user-level settings default is already auto/bypass.
- Parallelism: `CODEBUDDY_CODE_MAX_CONCURRENT_SUBAGENTS` (matrix default 8).

## 6. Specific constraints

- **`cbc-herdr` must be registered** (the three panes `dmt-director` / `dmt-dm` / `dmt-am`): cbc is not in herdr's compile-time built-in support list, so it relies on `cbc-herdr` to report working / idle / blocked; otherwise `agent_status` is permanently `unknown` (the readiness check becomes ineffective).
- The basename of the foreground process argv is **`cbc`** (not `codebuddy`) — when judging the harness / auto mode from argv, recognize this alias (`harness-detect.sh` already has it built in).
- Concurrency cap `CODEBUDDY_CODE_MAX_CONCURRENT_SUBAGENTS` (matrix default 8).
