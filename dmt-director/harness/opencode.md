# harness differences: opencode

> For the shared parts see [`COMMON.md`](COMMON.md); the single source of machine-readable facts is [`../harness_matrix.yaml`](../harness_matrix.yaml).

## 1. Skill discovery directories

| Level | Directories |
|---|---|
| Project level | `.agents/skills/`, `.claude/skills/`, `.opencode/skills/` (**plural**) |
| User level | `~/.agents/skills/`, `~/.claude/skills/` |

- **The singular `.opencode/skill/` does not take effect at project level** (measured; on this machine both exist side by side in old install directories, which is easy to misjudge).
- It reads `.claude/skills/` ⇒ shares one landing location with claude.

## 2. Startup and permissions

`opencode --auto`; the auto-mode check is argv containing `--auto` (and `--dangerously-skip-permissions`).

## 3. Skill invocation line

`/<skill name>`.

**2026-11-05 measurement addendum (important)**:

- **The slash-command list is incomplete**: measured, `/to-spec` and `/to-tickets` **did not make it into** opencode's slash list and typing them has no effect; however the **`skill` tool can load by id** (`implement` / `tdd` / `code-review` / `research` all succeeded in measurements, including those with `disable-model-invocation: true`).
- ⇒ **Prefer the `skill` tool** (the id is the skill name); when the tool is also unavailable, read `SKILL.md` directly per §4. This is exactly the fallback the director took in measurements: it reported "`/to-spec`, `/to-tickets` are not in this project's opencode skill list" and switched to reading `~/.agents/skills/mattpocock-skills/skills/engineering/<name>/SKILL.md` directly.
- **The doorbell (`herdr agent prompt`) works**: measured, `send-msg.sh` sending to `director` succeeded (no WARN, the recipient claimed and closed out). But for **the first few tens of seconds after the first startup** input may not be ready ⇒ after the first skill injection, re-check whether the pane output actually starts working (send an extra `send-keys enter` if needed).

## 4. How skills reach the model

- Skills enter the list and can be invoked with a slash; when they cannot be invoked, read the skill file path instead.
- Subagents: hosted by the harness's own parallel subagent mechanism (for the template see [`../team/07b-dispatch.md`](../team/07b-dispatch.md)).

## 5. Mandatory skills

`/<name>`.

## 6. Specific constraints

- **Concurrency cap**: upstream opencode 2.2.5 **provides no concurrency entry point**, and the matrix explicitly records it as `null` (this is not an omission) ⇒ judge by task size before dispatching, with no hard cap.
- `cbc-herdr` is **not** needed (herdr recognizes opencode natively).