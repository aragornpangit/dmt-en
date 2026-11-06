# harness commonality (shared by pi / codebuddy / claude / codex / opencode)

> **This is the "skill loading" common half**: this file plus one harness delta file ([`pi.md`](pi.md) / [`codebuddy.md`](codebuddy.md) / [`claude.md`](claude.md) / [`codex.md`](codex.md) / [`opencode.md`](opencode.md)) together form the complete rules.
> **How to load**: "## 0. Load per harness" in the seven role `SKILL.md` files is the only entry point — first run `dmt-director/scripts/harness-detect.sh`, then read this file (common) plus `<harness>.md` (delta).
> **Cannot find / cannot determine**: `unknown` ⇒ report back to director, **must not default to some harness**.

## 1. Skill list and role mapping

| Role (runtime id) | Skill directory name | Form |
|---|---|---|
| `director` | `dmt-director` | persistent pane |
| `devm` | `dmt-dm` | persistent pane |
| `anam` | `dmt-am` | persistent pane |
| `pde{n}` | `dmt-pde` | subagent |
| `dev-e` | `dmt-de` | subagent |
| `ana-e` | `dmt-ae` | subagent |
| `reviewer{n}` | `dmt-reviewer` | subagent |

Skill name = directory name; runtime ids are used only for pane labels, inbox directories, and direction codes (the three layers are never mixed, see [`../team/01-org.md`](../team/01-org.md)).

## 2. Mandatory-skill policy (identical across the five harnesses)

- Mandatory skills are **not a suggestion**: every role **must** invoke them in its responsible actions; silently skipping them on the grounds of "hand-writing is faster" or "the skill is not installed" is not allowed.
- Not available ⇒ first install per §3; still not available ⇒ mark `[SKILL_UNAVAILABLE]` in the artifact and the report and report back to director for a ruling.
- **Invocation must leave a trace**: the report states which skill was used and where the output went.
- The per-role list is [`../team/03-comms.md`](../team/03-comms.md) §1.4 (**sole authority**; this file does not repeat it).

## 3. Skill sources and install fallback

- mattpocock skills: `npx skills@latest add mattpocock/skills -a <agent>`; on failure, clone `https://github.com/mattpocock/skills.git` and place the skill directories into **the directory that harness recognizes** (see the delta file §1).
- Skill names must match the upstream directory names **verbatim**; `/rea` belongs to REA and keeps its original name (on pi it is an MCP tool, see `pi.md` §5).
- The five harnesses have **different skill discovery directories** (`.agents/skills/` covers only codex / opencode / pi) ⇒ install for whichever harness and symlink into that harness's directory; `install-skills.sh --harness all` lays down three locations by default.

## 4. Reloading after skill changes

After skill directories / skill names change, **already-running panes will not see it automatically**: use `setup-team.sh --reload` or reopen the pane.

## 5. Skill budget and single source

Each `SKILL.md` has a byte budget (`../dmt_contract.yaml: skill_budgets`); exceeding it turns the machine check red. Common policy (organization / permissions / gates / parallelism / naming / harness deltas) is **always written as pointers**, never inside role skills.

## 6. Shared boundaries for subagents

Subagents (`pde{n}` / `dev-e` / `ana-e` / `reviewer{n}`) **do not occupy a pane and do not enter the inbox**; they report only to their spawner; skills are delivered with the dispatch prompt ([`../team/07b-dispatch.md`](../team/07b-dispatch.md)). **How to put skills into a subagent's hands** is each harness's delta (see the delta file §4).

## 7. Two shared disciplines (added from 2026-11-05 measurements on both pi and claude)

- **Artifact boundaries**: subagents write **only to paths explicitly named in the prompt** (e.g. `docs/analyst/evidence/<unit>/`), and must not pile intermediate captures (`.java` samples / `.aar` / HTML reports / logs) into other directories under `docs/` or the project root. Measured: one subagent piled 26 capture files into the working directory ⇒ polluting `docs/analyst/evidence/`.
- **Load ≠ start work**: after a skill is loaded, **stop at the readiness report** (wait for dispatch); do not start changing the repository on your own just because "you read that the project has tickets in flight". Measured: three panes started working spontaneously after loading, and `devm` actually created a detached worktree (after noticing the overreach it ran `git worktree remove --force` itself and declared it) ⇒ under yolo/auto tiers this is a risk that can directly corrupt the repository.
