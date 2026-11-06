# harness directory (loaded per harness)

The **per-harness loading** rules for skills live here, split into "one shared half + one delta per harness":

- [`COMMON.md`](COMMON.md) — what the five harnesses (pi / codebuddy / claude / codex / opencode) have **in common**.
- [`pi.md`](pi.md) / [`codebuddy.md`](codebuddy.md) / [`claude.md`](claude.md) / [`codex.md`](codex.md) / [`opencode.md`](opencode.md) — the **delta** for each harness.

**Loading protocol** (the only entry point is "## 0. Load per harness" in the seven role `SKILL.md` files):

1. `bash dmt-director/scripts/harness-detect.sh` determines this session's harness (`pi|codebuddy|claude|codex|opencode`; `unknown` ⇒ report back to director, must not fall back to a default).
2. Read the shared half and the delta: `harness/COMMON.md` + `harness/<harness>.md`.
3. Execute per the delta file's "how skills reach the model / mandatory skill invocation line / subagent carriage".

**pi subagent agent definitions**: `pi-agents/` provides one agent definition for each of dmt's four subagent roles (`inheritSkills: false` plus a `skills:` allowlist), laid down into the target project's `.pi/agents/` by `install-skills.sh --harness pi` — this solves pi subagents' "no skill list, no Skill tool" problem. Mechanism and measurements: [`pi.md`](pi.md) §4.1.

**Test report and improvement list**: end-to-end measurements across the five harnesses are in `logs/2026-11-06-harness-test-report.md`（仓内）; per-harness defects and improvement status (with criteria) are in [`BACKLOG.md`](BACKLOG.md).

**Single source**: machine-readable facts such as directories / slash prefixes / launch commands / concurrency caps live **only** in [`../harness_matrix.yaml`](../../dmt-director/harness_matrix.yaml); the `.md` files in this directory are explanations for humans / models, and consistency between the two is guarded by machine checks (A8).

**Operations layer**: pane shapes, launch order, and permission-tier re-verification are in [`../ops/runtime.md`](../ops/runtime.md); the doorbell and inbox are in [`../ops/comms.md`](../ops/comms.md).
