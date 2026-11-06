# harness differences: claude (Claude Code)

> For the shared parts see [`COMMON.md`](COMMON.md); the single source of machine-readable facts is [`../harness_matrix.yaml`](../../dmt-director/harness_matrix.yaml).

## 1. Skill discovery directories

| Level | Directories |
|---|---|
| Project level | `.claude/skills/` |
| User level | `~/.claude/skills/` |

It does **not read** `.agents/skills/` (measured per-harness with probes on 2026-11-04; project-level symlinks are followed correctly, no need to copy).
Note that `opencode` **also reads** `.claude/skills/` ⇒ the same landing location is shared by two harnesses.

## 2. Startup and permissions

`claude --permission-mode auto`; the auto-mode check reads argv (`--permission-mode auto`; `--dangerously-skip-permissions` is also recognized by the check, see `dmt_pane_auto_mode`).

**Two ways it differs from codebuddy** (claude-side measurement correction on 2026-11-05):

1. **No local reviewer** — codebuddy's setup (`auto-review-model.sh` health gate + 300s budget + `permissions.allow` allowlist) **does not apply** to claude (there is no `autoModeClassifier` endpoint concept).
2. **The `auto` level depends on a remote classifier and gets rate-limited** — measured, in one round of 122 Bash calls, 9 were rejected outright with `… temporarily unavailable (rate-limited)` (the symptom is a failed command; the root cause is the permission layer). If this bothers you: switch to `--dangerously-skip-permissions` (yolo level, skips the classifier; `dmt_pane_auto_mode` still returns rc=0), or accept occasional retries.
3. Also: if the user-level `~/.claude/settings.json` sets `permissions.defaultMode`, argv may **omit** the level parameter while permissions are actually auto — in that case `dmt_pane_auto_mode` reading argv gives rc=2/1 (cannot obtain, or judged non-auto), which is a **known false-positive surface**; confirm manually and then allow it.

## 3. Skill invocation line

`/<skill name>`, e.g. `/dmt-dm`.

## 4. How skills reach the model

- Same path as codebuddy: skills enter the list and can be invoked with a slash; when `/<name>` cannot be invoked, read the skill file path instead.
- Subagents: hosted by the harness's own subagent mechanism; for the dispatch template see [`../team/07b-dispatch.md`](../team/07b-dispatch.md).

## 5. Mandatory skills

`/<name>` (e.g. `/code-review`).

## 6. Specific constraints

- Concurrency cap 10; environment variables `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (plus `CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`) — measured, the claude binary contains these two keys, already filled into the matrix `max_subagents_env`.
- `cbc-herdr` is **not** needed (herdr recognizes claude natively).
- **Duplicate user-level and project-level installs**: when user-level `~/.claude/skills/dmt-*` and project-level `.claude/skills/dmt-*` coexist, non-dmt projects also pick up the user-level copy (its version may lag) ⇒ it is recommended to keep only the project level, or ensure the user level is a symlink into the repo.
