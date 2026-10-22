# dmt

Role skills for the dmt team: **the single maintenance point for the team definition and its five role skills**. Four levels: `director` → department manager (`dev-m` / `ana-m`) → team lead (`dev-tl{n}` / `ana-tl{n}`) → engineer (`dev-e` / `ana-e`).

| Role | Skill | tab label | Reports to | Direct reports | Responsibility in one line |
|---|---|---|---|---|---|
| Director (team lead + product manager) | `director` | `director` | User | `dev-m`, `ana-m` | Take requirements, set acceptance criteria, write the PRD and SPEC personally, review research reports and ticket code, arbitrate across departments |
| Development manager | `dev-m` | `dev-m` | `director` | `dev-tl{n}` | Split the SPEC into tickets, spawn development team leads on demand, integrate and accept, push only after director approval |
| Analysis manager | `ana-m` | `ana-m` | `director` | `ana-tl{n}` | Take research requests, spawn analysis team leads on demand, consolidate research reports |
| Development team lead | `dev-tl` (instance `dev-tl{n}`) | `dev-tl1`, `dev-tl2` … | `dev-m` | `dev-e` (sub-agent) | Create the worktree, dispatch development engineers, check the diff, report to dev-m |
| Analysis team lead | `ana-tl` (instance `ana-tl{n}`) | `ana-tl1`, `ana-tl2` … | `ana-m` | `ana-e` (sub-agent) | Split sub-questions, dispatch analysis engineers in parallel, verify sources, report to ana-m |

**Single-line command**: each role talks only to its direct superior and direct reports; the director never skips levels to team leads or engineers, managers never task engineers directly, team leads never talk to each other, managers never talk sideways, and every cross-department matter is relayed by the director.
Team leads are **spawned on demand, never pre-created**: dev-m runs `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label dev-tl{n}` for a development team lead, and ana-m runs the same command with `ana-tl{n}`.

Members run inside Herdr, a terminal multiplexer for AI agents, and **identify peers by tab label**; pane ids are re-resolved before every send.
**Inter-role communication = inbox file + herdr doorbell**: the body goes into the receiver's `inbox/<recipient>/{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (project root, not under `docs/`), herdr carries one line ("you have a new message …"), and the receiver replies "… received" and deletes the file (details in `team.md` §1.3).
Workflow in one line: ana-m dispatches analysis team leads to research (director reviews) → director writes the PRD and SPEC (dev-m reviews) → dev-m splits tickets and spawns development team leads → team leads dispatch dev-e, implement and run the first check → dev-m integrates → director approves → dev-m `git push`.

**Team contract (the single authority on organization, communication, file naming, directory ownership and discipline) = [`team.md`](team.md).**

```
dmt/                                    # one folder per role
├── director/                           # Director, also product manager (skill director)
│   ├── SKILL.md
│   ├── team.md                         # team contract (single authority)
│   ├── README.md                       # this file
│   └── scripts/check-pda-doc-paths.sh  # output-path checker
├── dev-m/SKILL.md                      # Development manager (dev-m)
├── ana-m/SKILL.md                      # Analysis manager (ana-m)
├── dev-tl/SKILL.md                     # Development team lead (dev-tl{n})
└── ana-tl/SKILL.md                     # Analysis team lead (ana-tl{n})
```

## Installing into a project

The folder name in this repo is the skill name (`director` / `dev-m` / `ana-m` / `dev-tl` / `ana-tl`); **copy them under the same names** into the skill directory.

```bash
mkdir -p <project>/.agents/skills/{director,dev-m,ana-m,dev-tl,ana-tl} <project>/scripts \
         <project>/docs/{pd/{prd,spec},dev/tickets,research,user/{user-arch,user-plan}} \
         <project>/inbox/{director,dev-m,ana-m}
cp director/SKILL.md  <project>/.agents/skills/director/
cp dev-m/SKILL.md     <project>/.agents/skills/dev-m/
cp ana-m/SKILL.md     <project>/.agents/skills/ana-m/
cp dev-tl/SKILL.md    <project>/.agents/skills/dev-tl/
cp ana-tl/SKILL.md    <project>/.agents/skills/ana-tl/
cp director/team.md <project>/docs/team.md
cp director/scripts/check-pda-doc-paths.sh <project>/scripts/
printf 'inbox/*/\n' >> <project>/.gitignore        # the inbox is a runtime channel, not versioned
```

To follow updates from this repo, use **relative symlinks** instead (recommended; assuming the project sits next to this repo):

```bash
ln -s ../../../dmt/director <project>/.agents/skills/director
ln -s ../../../dmt/dev-m <project>/.agents/skills/dev-m     # ana-m / dev-tl / ana-tl likewise
ln -s ../../dmt/director/team.md <project>/docs/team.md
ln -s ../../dmt/director/scripts/check-pda-doc-paths.sh <project>/scripts/check-pda-doc-paths.sh
```

Symlinking the whole role directory exposes the contract, README and checker under `director/` without affecting skill loading.
For other harnesses (codebuddy / codex / opencode …) in a user-level skill directory, the rule is the same: **the folder name is the skill name**.

## Checker

```bash
bash director/scripts/check-pda-doc-paths.sh <project root>   # checks the current directory when omitted
# override with PDA_SKILLS_DIR when the skills are not under <project>/.agents/skills (default on line 9 of the script)
```

Four checks: the six output directories plus the root `inbox/` exist (**the director fills gaps at initialization**, see `team.md` §3.1); the five role skills each point at their own directory; this contract registers every path; a negative sample is rejected. **Rerun after any path change.**

## Maintenance

- This repo is the **single maintenance point** for dmt; consumers keep no copy. With symlinks, skills and contract update with the repo and take effect immediately (no reinstall).
- Contract references inside the skills do not depend on relative paths (written as "`director/team.md` (this repo; `docs/team.md` once installed)"), so symlink installs never break.
- Harness-side skills required: `herdr` (communication and tab creation), `pi-subagents` (sub-agents and dynamic workflow), plus mattpocock's `/to-spec`, `/to-tickets`, `/code-review`, `/tdd`, `/research` and friends (install and fallback in `team.md` §1.4).
