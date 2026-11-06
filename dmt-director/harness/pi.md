# harness delta: pi (pi-coding-agent)

> For commonality see [`COMMON.md`](COMMON.md); machine-readable facts (directories / prefixes / launch / concurrency) single source [`../harness_matrix.yaml`](../../dmt-director/harness_matrix.yaml).
> Except where noted, this section is **entirely measured on this machine on 2026-11-05** (`harness-detect.sh` re-checked pane by pane plus `pi -p --approve` session probes).

## 1. Skill discovery directories

| Level | Directories |
|---|---|
| Project level | `.agents/skills/`, `.pi/skills/` |
| User level | `~/.agents/skills/`, `~/.pi/agent/skills/` |

- **Project-level `.agents/skills/` is trust-requiring**: without `--approve` at launch it is invisible (only user-level skills are seen).
- **`~/.pi/skills/` is not read** — even if symlinks are placed in that directory they do not take effect (measured on this machine: the directory exists and is full of symlinks, but not a single one was loaded).
- When the same-named skill is installed at both project and user level, both appear (on name conflicts pi keeps the first discovered one and warns).

## 2. Launch and permissions

- The delegated launch command is `pi --approve` (`lib-dmt.sh: dmt_harness_cmd pi`).
- `--approve` is also **the auto-tier criterion** (`dmt_pane_auto_mode` recognizes it). pi has no per-item approval gate; `--approve` only concerns trust of project-level resources.

## 3. Skill invocation line (pane roles)

- **`/skill:<skill-name>`**: `/skill:dmt-director`, `/skill:dmt-dm`, `/skill:dmt-am`.
- **Writing `/dmt-dm` does not error, but is treated as an ordinary question** (silently ineffective) ⇒ always generate it via `lib-dmt.sh: dmt_skill_cmd`, never type it by hand.

## 4. How skills reach the model

**pi's two hard limits** (measured 2026-11-05):

1. **No Skill tool** — the model cannot "invoke a skill" itself, it can only read `SKILL.md`; skill body text reaches the context through only three routes: the user / dispatcher typing `/skill:<name>`, the launch parameter `--skill <path>`, and the `<available_skills>` catalog in the system prompt (whether it exists is decided by `inheritSkills` / `skills`).
2. **Subagents do not inherit skills by default** — the built-in `delegate` agent definition is `inheritSkills: false` (measured: its system prompt has **no** `<available_skills>` section), so in a subagent you can neither type `/skill:` nor see a catalog.

### 4.1 Subagent side: inject skills via a custom agent definition (recommended fix)

pi-subagents allows custom agents (`~/.pi/agent/agents/**/*.md` user level, `<project>/.pi/agents/**/*.md` project level); the frontmatter supports three key fields: `inheritSkills`, `skills`, `skillPath`.

**Three measured granularities** (same project, same dispatch method, only the agent definition changed):

| Agent definition | `<available_skills>` in the subagent system prompt | Applicable to |
|---|---|---|
| built-in `delegate` (`inheritSkills: false`, no `skills`) | **none** | one-off script work; give skill paths via the prompt |
| `inheritSkills: false` + `skills: dmt-pde` | **only `dmt-pde`** (exact allowlist) | **recommended for dmt's four subagent roles** (least privilege) |
| `inheritSkills: true` + `skills: [...]` | **the full skill catalog** (all seven dmt-* plus tdd/code-review etc.) | general-purpose agents that need autonomous discovery |

⇒ **dmt's landing form**: write one agent definition for each of `dev-e` / `ana-e` / `pde{n}` / `reviewer{n}`, with `inheritSkills: false` plus `skills:` listing that role's role skill and mandatory skills exactly. Templates in [`pi-agents/`](pi-agents/README.md) (`install-skills.sh --harness pi` lays them into the project's `.pi/agents/`).

**Semantics note**: `skills` is a "selected subset", `inheritSkills: true` is "keep the parent's whole catalog"; when both are given, **the allowlist only wins if `inheritSkills: false`** (measured: with `inheritSkills: true` it is the full catalog and `skills` does not trim it).

### 4.2 Pane side: load skills via launch parameters or slash commands

| Route | Measured | Notes |
|---|---|---|
| `pi --skill <skill directory>` | ✅ loaded successfully (**project-level paths also work, no `--approve` needed**) | one pane may repeat `--skill` multiple times; good for "start with the role skill already loaded" |
| `pi --approve` plus project `.agents/skills/` | ✅ auto-discovered | without `--approve` only the files are seen, they do not enter the catalog (measured: the model answered "on disk but not loaded") |
| input box `/skill:dmt-<role>` | ✅ | writing `/dmt-<role>` does not error but **silently becomes an ordinary question** |
| user-level `~/.agents/skills/`, `~/.pi/agent/skills/` | ✅ | no approve needed |

**Measurement addendum (2026-11-06, three real subagents echoing their `<available_skills>`)**

| agent definition | declared `skills:` | actually injected | filtered out |
|---|---|---|---|
| `dmt-dev-e` | `dmt-de, tdd, implement, code-review, diagnosing-bugs` | `dmt-de, tdd, code-review, diagnosing-bugs` | `implement` |
| `dmt-pde` | `dmt-pde, grilling, research, to-spec, to-tickets` | `dmt-pde, grilling, research` | `to-spec`, `to-tickets` |
| `dmt-ana-e` | `dmt-ae, research, grilling, grill-me, grill-with-docs` | `dmt-ae, research, grilling` | `grill-me`, `grill-with-docs` |

⇒ every filtered skill carries `disable-model-invocation: true`. The drop is **silent, with no warning**, so "declared equals available" is false and must be measured.

### 4.3 Fallback (kept as-is)

When none of the above applies (e.g. changing agent definitions is not permitted): give the **absolute path** in the dispatch prompt as `read <skill directory>/dmt-<role>/SKILL.md`, and handle forwarding skills per `§5.1`. This always works, but it relies on the model following the prompt and requires listing a path for every downstream skill.

### 4.4 Known pitfalls

- **Duplicate registration of same-named skills**: measured, `tdd` / `code-review` each appear twice in the subagent catalog (`~/.agents/skills/mattpocock-skills/...` and the pi git package, one each) ⇒ naming them explicitly in `skills:` avoids the ambiguity; when both are installed, prefer keeping a single copy.
- **`delegate`'s tools allowlist does not include `subagent`** (its definition is `tools: read, grep, find, ls, bash, edit, write, contact_supervisor`) ⇒ subagents cannot spawn subagents; when nesting is needed add `allowNestedSubagents: true` or `tools: subagent` in the custom agent.
- **Project-level agent definitions are equally trust-constrained**: when Pi has not approved project trust, project agents are ignored (`agentScope` falls back to user).
- Skills with `disable-model-invocation: true` (`to-spec` / `to-tickets` / `implement` / `grill-me` / `grill-with-docs` etc.) **do not appear in the model-visible catalog**; `/skill:<name>` can still invoke them explicitly, but **listing them in a custom agent's `skills:` is filtered as well** (2026-11-06 measurement disproved the earlier note that the flag only affects model auto-selection): 5 declared, 4 delivered, and `to-spec`/`to-tickets` both silently dropped with **no error**. ⇒ put only flag-free skills in `skills:`; give the filtered ones a `SKILL.md` path in the agent prompt and let the subagent `read` it (all four `pi-agents/` files are shaped this way).

## 5. How to obtain the mandatory skills (mattpocock) on pi

- Pane roles: `/skill:<name>` (e.g. `/skill:code-review`); those with `disable-model-invocation` **must be typed explicitly**, the model will not think of them by itself.
- Subagents: they can only read files; real paths (measured usable on this machine):
  - `~/.pi/agent/git/github.com/mattpocock/skills/skills/engineering/<name>/SKILL.md`
  - `~/.pi/agent/git/github.com/mattpocock/skills/skills/productivity/<name>/SKILL.md`
  - Do **not** use `~/.agents/skills/mattpocock-skills/**`: on this machine `settings.skills` already excludes it with `!~/.agents/skills/mattpocock-skills/**`.
- **`/rea` is not a skill on pi**: REA is provided as an **MCP tool** (`mcp__rea`); just use the tool directly.

### 5.1 Forwarding skills must be downgraded (measured 2026-11-05 across three roles)

Some mattpocock skill bodies only say `Call the Skill tool with "<other skill>"`, and pi **has no Skill tool** ⇒ following the body text results in **silent failure** (the skill "runs", but the internal forwarding step never happens).

**Rule**: in the body text, such sentences are always changed to `read <mirror root>/{engineering,productivity}/<other skill>/SKILL.md` and then executed accordingly. Affected dmt mandatory skills:

| Skill | Body requirement | Downgrade on pi |
|---|---|---|
| `grill-with-docs` | `Call the Skill tool twice, for "grilling" and "domain-modeling"` | read `grilling` (productivity/) + `domain-modeling` (engineering/) |
| `grill-me` | `Call the Skill tool with "grilling"` | read `grilling` |
| `implement` | `Call the Skill tool with "tdd"` / `"code-review"` | read `tdd` + `code-review` |
| `tdd` | `call the Skill tool with "codebase-design"` (**advisory**, not mandatory) | read `codebase-design` (optional) |

Two measured cautions:

- `grill-with-docs`'s body is **only that one sentence** ⇒ not downgrading equals doing nothing (you must explicitly read both sub-skills).
- Skill directories are **not uniform**: `grill-with-docs` is under `engineering/`, **not** under `productivity/` ⇒ when not found, try both directories (measured: one role looked under `productivity/` first and wrongly concluded it did not exist).
- The same holds for subagents, and they **cannot invoke downstream skills automatically**: the spawner must give the absolute path of the next skill in the chain in the prompt (measured: inside a dev-e subagent neither `/tdd` nor `/code-review` could be invoked).

## 6. Subagent carriage

- `dev-e` / `ana-e` / `pde{n}` / `reviewer{n}` are **role semantic names**, not agent registration names in pi-subagents; dispatching directly by role name reports `Unknown agent: <role name>` (reproduced 2026-11-05).
- In pi workflows set the `agent` field to the built-in **`delegate`** (no preset behavior, inherits the parent model) and put the role semantics in the prompt. Templates in the "pi harness carriage" section of [`../team/07b-dispatch.md`](../team/07b-dispatch.md).
- **Optional enhancement (not yet wired)**: pi-subagents supports custom agent definitions (`~/.pi/agent/agents/*.md`, project `.pi/agents/*.md`, legacy `.agents/**/*.md`) with fields `inheritSkills` / `skills` / `tools` ⇒ a definition can be registered for each of the four subagent roles, enabling "dispatch directly by role name" plus skill inheritance plus a tools allowlist. Currently dmt uses the `delegate` downgrade path.

## 7. pi-specific constraints

- **`cbc-herdr` is not needed**: herdr recognizes pi natively (manifest `pi.toml`; visible via `herdr agent explain`), so `agent_status` is directly trustworthy.
- **Concurrency cap**: the matrix already has **8** (pi-subagents default workflow `maxTasks=8` / `concurrency=4`, overridable per call via `concurrency`; there is also `maxConcurrentAsyncRuns` limiting the number of top-level async runs, `0` = unlimited).
- **Doorbell**: `herdr agent prompt <pane>` works for pi panes (agent kind = `pi`); when it does not return `agent_prompted`, fall back to `pane send-text` + `pane send-keys enter` (already built into `send-msg.sh`).
- **Timing risk (not measured)**: `dmt_wait_ready` only waits for `agent_status != unknown`, and the pi TUI starts slowly ⇒ `/skill:…` may arrive before the input is ready; after launch use `dmt_confirm_role_ready` to re-verify that the skill is really loaded by "the role name plus the one-time credential appearing together in the pane output".
