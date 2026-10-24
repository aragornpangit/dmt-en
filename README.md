# dmt

Role skills for the dmt team: **the single maintenance point for the team definition and its five role skills**. Four levels: `director` → department manager (`devm` / `anam`) → team lead (`devtl{n}` / `anatl{n}`) → engineer (`dev-e` / `ana-e`).
**The team-lead level is on demand**: when a manager needs to spread work in parallel it opens a lead pane inside **its own tab** with `herdr pane split` (pane label `devtl{n}`), and the lead then spawns the engineer sub-agents. The lead pane is closed once its batch is done.

| Role | Skill | pane label | Reports to | Direct reports | Responsibility in one line |
|---|---|---|---|---|---|
| Director (team lead + product manager) | `director` | `director` | Human | `devm`, `anam` | Take requirements, set acceptance criteria, write the PRD and SPEC personally, review research reports and ticket code, arbitrate across departments |
| Development manager | `devm` | `devm` | `director` | `devtl{n}` (pane, on demand) | Split the SPEC into tickets; open lead panes on demand; integrate and accept; push only after director approval |
| Analysis manager | `anam` | `anam` | `director` | `anatl{n}` (pane, on demand) | Take research requests; open lead panes on demand; verify sources, consolidate research reports |
| Development team lead | `devtl` (instance `devtl{n}`) | `devtl1`, `devtl2` … | `devm` | `dev-e` (sub-agent) | Created on demand by the manager; create the worktree, dispatch development engineers, check the diff, report to devm |
| Analysis team lead | `anatl` (instance `anatl{n}`) | `anatl1`, `anatl2` … | `anam` | `ana-e` (sub-agent) | Created on demand by the manager; split sub-questions, dispatch analysis engineers in parallel, verify sources, report to anam |

**Display names**: prose, reports and logs use Director / Development manager / Analysis manager / Development team lead / Analysis team lead (with the instance number, e.g. "lead 1"); **pane labels, inbox folders, direction codes and commands use the ids** (`director` / `devm` / `anam` / `devtl{n}` / `anatl{n}` / `dev-e` / `ana-e`). Never mix the two: `inbox/devtl1/` is a path, "lead 1 reported …" is prose.

**Single-line command**: each role talks only to its direct superior and direct reports; the director never skips levels to team leads or engineers, team leads never talk to each other, managers never talk sideways, and every cross-department matter is relayed by the director. **Engineers are always sub-agents** (no pane, no cross-pane communication): the lead spawns them — there is no pane-level channel between a manager and an engineer, only a parent-child sub-agent relation.
Team leads are **spawned on demand and closed on completion**: the manager runs `herdr pane split "$HERDR_PANE_ID" --direction right --cwd "$PWD" --no-focus` inside **its own tab** and then `herdr pane rename <pane> devtl{n}` (anam does the same with `anatl{n}`), and starts the harness for it (`codebuddy --permission-mode auto`). When the batch is fully closed out and no next batch is confirmed, **the creator itself** closes it with `herdr pane close <pane>` (the pane resolved from the **pane label** via `herdr pane list`). **Three preconditions** (report filed, worktree removed with `git worktree remove`, no unread inbox message from that lead) come in a fixed order and none is optional; **never close before collecting** (closing kills the agent session and the context cannot be recovered); **`herdr tab close` is forbidden** (the lead shares the manager's tab); **reusable within a batch, never carried across batches**; a non-creator never closes on someone's behalf. Details in `team.md` §1.2.

Members run inside Herdr, a terminal multiplexer for AI agents, and **identify peers by pane label** (the label equals the role name and is unique in the workspace; never by position inside a tab); pane ids are re-resolved before every send.
**Inter-role communication = inbox file + herdr doorbell**: the body goes into the receiver's `inbox/<recipient>/{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (project root, not under `docs/`), herdr carries one line ("you have a new message …"), and the receiver **does not send a receipt**, loads it into context and deletes the file (details in `team.md` §1.3).
Workflow in one line: anam opens a lead pane and researches (director reviews) → director writes the PRD and SPEC (devm reviews) → devm splits tickets and opens a lead pane → the lead spawns dev-e to implement and check → devm integrates → director approves → devm `git push`.

**Team contract (the single authority on organization, communication, file naming, directory ownership and discipline) = [`team.md`](team.md).**

```
dmt/                                    # one folder per role
├── README.md                                 # project overview (this file)
├── director/                           # Director, also product manager (skill director)
│   ├── SKILL.md
│   ├── team.md                         # team contract (single authority)
│   ├── README.md                       # pointer to root README.md
│   └── scripts/check-dmt-doc-paths.sh  # output-path checker
├── devm/SKILL.md                      # Development manager
├── anam/SKILL.md                      # Analysis manager
├── devtl/SKILL.md                     # Development team lead (devtl{n})
└── anatl/SKILL.md                     # Analysis team lead (anatl{n})
```

## Installing into a project

The folder name in this repo is the skill name (`director` / `devm` / `anam` / `devtl` / `anatl`); **copy them under the same names** into the skill directory.

```bash
mkdir -p <project>/.agents/skills/{director,devm,anam,devtl,anatl} <project>/scripts \
         <project>/docs/{pd/{prd,spec},dev/tickets,analyst,human/{human-arch,human-plan}} \
         <project>/inbox/{director,devm,anam}
cp director/SKILL.md  <project>/.agents/skills/director/
cp devm/SKILL.md     <project>/.agents/skills/devm/
cp anam/SKILL.md     <project>/.agents/skills/anam/
cp devtl/SKILL.md    <project>/.agents/skills/devtl/
cp anatl/SKILL.md    <project>/.agents/skills/anatl/
cp director/team.md <project>/docs/team.md
cp director/scripts/check-dmt-doc-paths.sh <project>/scripts/
printf 'inbox/*/\n' >> <project>/.gitignore        # the inbox is a runtime channel, not versioned
```

To follow updates from this repo, use **relative symlinks** instead (recommended; assuming the project sits next to this repo):

```bash
ln -s ../../../dmt/director <project>/.agents/skills/director
ln -s ../../../dmt/devm <project>/.agents/skills/devm     # anam / devtl / anatl likewise
ln -s ../../dmt/director/team.md <project>/docs/team.md
ln -s ../../dmt/director/scripts/check-dmt-doc-paths.sh <project>/scripts/check-dmt-doc-paths.sh
```

Symlinking the whole role directory exposes the contract, README and checker under `director/` without affecting skill loading.
For other harnesses (codebuddy / codex / opencode …) in a user-level skill directory, the rule is the same: **the folder name is the skill name**.

## Checker

```bash
bash director/scripts/check-dmt-doc-paths.sh <project root>   # checks the current directory when omitted
# override with DMT_SKILLS_DIR when the skills are not under <project>/.agents/skills (default on line 9 of the script)
```

Six checks: the six output directories plus the root `inbox/` exist (**the director fills gaps at initialization**, see `team.md` §3.1); the five role skills each point at their own directory; **the team-lead close action is registered** (the contract and the `devm` / `anam` skills contain `herdr pane close`, and the contract forbids closing before collecting and bans `herdr tab close`); **identity resolution is registered** (the contract and all five skills contain `pane label`); **the team-lead parallelism criterion is registered** (`devtl` / `anatl` say the work "must run in parallel", and the contract says "≥2 ⇒ dispatch concurrently"); the contract registers every path; a negative sample is rejected (**only the §3 table is inspected**; history in §8 does not count). **Rerun after any change to paths, pane lifecycle or parallelism criteria.**

## Maintenance

- This repo is the **single maintenance point** for dmt; consumers keep no copy. With symlinks, skills and contract update with the repo and take effect immediately (no reinstall).
- Contract references inside the skills do not depend on relative paths (written as "`director/team.md` (this repo; `docs/team.md` once installed)"), so symlink installs never break.
- Harness-side skills required: `herdr` (pane control and label resolution), `pi-subagents` (sub-agents and dynamic workflow), plus mattpocock's `/to-spec`, `/to-tickets`, `/code-review`, `/tdd`, `/research` and friends (install and fallback in `team.md` §1.4).
