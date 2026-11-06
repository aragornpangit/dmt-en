### 1.3 Communication (inbox files + herdr doorbell)

**Operating details: see [`dmt-director/ops/comms.md`](../ops/comms.md)** — direction codes, paths, the doorbell and the three states.

### 1.4 Dependent harness skills (mattpocock, mandatory)

> **Single-source discipline**: team constants live only in `team.md`; `OPS.md` is the operational router.
> The seven skill `SKILL.md` files **record only the actions specific to that role** (how to do the work) and **must not restate** the team definitions in this file (organization / hierarchy / permissions / gates / write ownership / parallelism policy / naming). Wherever a skill refers to a shared policy, **always write it as a pointer** ("see `dmt-director/team.md` §X"), so contract changes converge in one place.
> Test: when a team policy changes (e.g. the parallelism policy), **only this file plus the pointer at the point of action in that role's skill** should need editing; "all 7 skills have to change the same sentence" must never recur.

**Mandatory policy**: the skills in the table below are **not optional suggestions** — each role **must** invoke them in its duty actions; **do not** silently skip them on the grounds of "writing it by hand is faster" or "the skill isn't installed". Skill unavailable ⇒ install it first (see the end of this section); still unavailable ⇒ mark `[SKILL_UNAVAILABLE]` in the artifact and the report and report to the director for arbitration. **Invocations must leave a trace** (which one was used, where the output is).

| Role | Mandatory skills | Used for |
|---|---|---|
| `director` | `/grilling`, `/grill-me`, `/grill-with-docs`, `/code-review`, `/to-spec`, `/to-tickets` | grilling requirements, self-reviewing the plan, cross-examining contracts/documents, spot checks, drafting SPECs and tickets |
| `devm` | `/code-review`, `/diagnosing-bugs` | self-review before integrating a review; defect triage and regression localization |
| `anam` | `/research`, `/grilling`, `/grill-me`, `/grill-with-docs` | primary-source evidence gathering and evidence grading, self-review of the research plan, cross-examining evidence |
| `pde{n}` | `/grilling`, `/research`, `/to-spec`, `/to-tickets` | criteria checking, fact gathering, SPEC/ticket decomposition and checking (the same set as the director) |
| `reviewer{n}` | `/code-review` | checking acceptance criteria, verdict points, diff, evidence and test output item by item (**written into the dispatch prompt**) |
| `dev-e` | `/tdd`, `/implement`, `/code-review`, `/diagnosing-bugs` | TDD implementation, delivering per the SPEC, self-review before commit, defect triage |
| `ana-e` | `/research`, `/rea`, `/grilling`, `/grill-me`, `/grill-with-docs` | evidence gathering, competitor reverse engineering (`/rea`, REA-only), cross-examination |

**Sub-agent skills**: `pde{n}` → `dmt-pde`, `dev-e` → `dmt-de`, `ana-e` → `dmt-ae`, `reviewer{n}` → `dmt-reviewer`. The dispatcher writes the skill name in the prompt; **the per-harness differences in "invocation line / whether to pass the skill file path / plugin prefix" load by harness** — see [`../harness/README.md`](../harness/README.md) (common part [`../harness/COMMON.md`](../harness/COMMON.md) plus `pi.md` / `codebuddy.md` / `claude.md` / `codex.md` / `opencode.md`; dispatch templates in [`07b-dispatch.md`](07b-dispatch.md)).

**Skill source files** (skill names match the upstream directory names in [`mattpocock/skills`](https://github.com/mattpocock/skills) **character for character**; `/rea` belongs to REA and is not in that repo, so it keeps its own name with no link):
[`/grilling`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grilling/SKILL.md), [`/grill-me`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grill-me/SKILL.md), [`/grill-with-docs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/SKILL.md), [`/code-review`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/code-review/SKILL.md), [`/to-spec`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-spec/SKILL.md),
[`/to-tickets`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-tickets/SKILL.md), [`/research`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/research/SKILL.md), [`/tdd`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/tdd/SKILL.md), [`/implement`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/implement/SKILL.md), [`/diagnosing-bugs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/diagnosing-bugs/SKILL.md), [`/improve-codebase-architecture`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/improve-codebase-architecture/SKILL.md) (**optional, not mandatory**; mentioned in the `dmt-dm` pointers)

**General skills (CodeBuddy pane only)**: `cbc-herdr` is used only for CodeBuddy status reporting inside herdr; Codex uses herdr's native status detection and does not load it. The cbc of `dmt-director` / `dmt-dm` / `dmt-am` must be registered; other harnesses and sub-agents do not register it.

**Installation**: `npx skills@latest add mattpocock/skills -a <agent>` (pi / opencode / codebuddy / amp / cursor / devin / windsurf); for Codex use `codex plugin marketplace add mattpocock/skills`, then `codex plugin add mattpocock-skills@mattpocock`. On failure, clone `https://github.com/mattpocock/skills.git`, copy the skill directories to `~/.agents/skills/` and symlink them into the harness skill directory; pick either the Codex plugin or the compatible copy, so the same skill is never registered twice.

**Harness differences**: `.agents/skills/` is read only by codex / opencode / pi; claude / codebuddy each use a private directory. Machine facts such as directories / prefixes / startup are in §1.2 and [`../../dmt-director/harness_matrix.yaml`](../../dmt-director/harness_matrix.yaml); how skills are loaded is in [`../harness/`](../harness/README.md).

**Known gaps**:

- Upstream has no `to-prd` yet ⇒ PRDs are drafted by pde using the §4.1 template.
- **Forwarding skills must be degraded on pi**: the body of `grill-with-docs` / `grill-me` / `implement` / `tdd` contains `Call the Skill tool with "<other skill>"`, but pi **has no Skill tool** ⇒ it must be changed to `read <mirror root>/<other skill>/SKILL.md` (skipping the degradation makes it fail silently; edge cases and measurements are in [`../harness/pi.md`](../harness/pi.md) §5.1).

### 1.5 File claims (check before editing)

**Operating details: see [`dmt-director/ops/file-claim.md`](../ops/file-claim.md)**.
