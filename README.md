# dmt

Role-skill repo for the dmt team: **the single maintenance point for the team definition and the six role skills**. Hierarchy: `director` → department manager (`pm` / `devm` / `anam`) → team lead (`devtl{n}` / `anatl{n}`, development and analysis departments only) → engineer (`dev-e` / `ana-e` / `pm-e`).
**The product department has only three levels**: `pm` spawns `pm-e` sub-agents directly and has no lead tier.
**The lead tier is on demand and has a numeric criterion**: a manager **spawns engineer sub-agents itself while its queued tasks stay within the threshold** (`devm` ≤4, `anam` ≤4); **once the threshold is exceeded** it opens a lead pane with `herdr pane split` **inside its own tab** (pane label fixed to `devtl{n}` / `anatl{n}`, **cbc harness preferred**, then types `/dmt-dtl` / `/dmt-atl`), and the lead spawns engineer sub-agents after taking the order; the lead pane is closed as soon as it is done.

| Role | Skill name | Runtime id (pane label) | Reports to | Direct reports | Responsibility summary |
|---|---|---|---|---|---|
| Director (team lead) | `dmt-director` | `director` | Human | `pm`, `devm`, `anam` | The only entry point; takes requirements and acceptance criteria, dispatches, arbitrates, creates and maintains the manager-tier panes/tabs; publishes after spot-checking (`git push`) and installs to devices; **does not replace** pm's document review or devm's code review |
| Product department manager | `dmt-pm` | `pm` | `director` | `pm-e` (sub-agent) | Writes the PRD, the SPEC ([`/to-spec`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-spec/SKILL.md)), development tickets ([`/to-tickets`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-tickets/SKILL.md)), the human architecture and the human plan; **document gate** (review owner for documents); uses sub-agents in parallel for product fact-finding and cross-checking |
| Development manager | `dmt-dm` | `devm` | `director` | `dev-e` (self-dispatch when ≤4) or `devtl{n}` (>4) | Takes tickets (pm's tickets), schedules and assigns work, **code gate** (review owner for ticket code), integrates deliverables; **does not split tickets and does not push** |
| Analysis manager | `dmt-am` | `anam` | `director` | `ana-e` (self-dispatch when ≤4) or `anatl{n}` (>4) | Takes research requests; self-dispatches sub-agents or opens lead panes by queue depth; verifies sources and closes out research reports |
| Development team lead | `dmt-dtl` | `devtl1`, `devtl2` … (inside devm's tab) | `devm` | `dev-e` (sub-agent) | Created on demand by the manager; creates the worktree, dispatches development engineers concurrently, collects diffs for a first pass, reports to devm |
| Analysis team lead | `dmt-atl` | `anatl1`, `anatl2` … (inside anam's tab) | `anam` | `ana-e` (sub-agent) | Created on demand by the manager; splits sub-questions, dispatches analysis engineers for parallel evidence gathering, verifies sources, reports to anam |

| Role | Mandatory skills (mattpocock, must be used) |
|---|---|
| Director `director` | [`/grilling`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grilling/SKILL.md) (grill the acceptance criteria), [`/grill-me`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grill-me/SKILL.md) (self-review of a plan), [`/grill-with-docs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/SKILL.md) (cross-examine contract/documents), [`/code-review`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/code-review/SKILL.md) (spot-check) |
| Product manager `pm` | [`/to-spec`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-spec/SKILL.md) (SPEC), [`/to-tickets`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-tickets/SKILL.md) (tickets), [`/grilling`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grilling/SKILL.md) (requirement clarification), [`/grill-me`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grill-me/SKILL.md), [`/grill-with-docs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/SKILL.md) |
| Development manager `devm` | [`/code-review`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/code-review/SKILL.md) (before integrating), [`/diagnosing-bugs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/diagnosing-bugs/SKILL.md) (defect triage) |
| Development lead `devtl` | [`/tdd`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/tdd/SKILL.md), [`/implement`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/implement/SKILL.md), [`/code-review`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/code-review/SKILL.md), [`/diagnosing-bugs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/diagnosing-bugs/SKILL.md) |
| Analysis manager `anam` | [`/research`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/research/SKILL.md), [`/grilling`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grilling/SKILL.md), [`/grill-me`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grill-me/SKILL.md), [`/grill-with-docs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/SKILL.md) |
| Analysis lead `anatl` | [`/research`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/research/SKILL.md), [`/grilling`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grilling/SKILL.md), [`/grill-me`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grill-me/SKILL.md), [`/grill-with-docs`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/SKILL.md) |
| Engineers `pm-e` / `dev-e` / `ana-e` | Forced through the dispatch prompt (see `team.md` §1.4) |

Skill names match [`mattpocock/skills`](https://github.com/mattpocock/skills) upstream **verbatim**, and every link points at the source file on `raw.githubusercontent.com`; `/rea` belongs to REA and is not in that repo, so it keeps its original name.

Also: the six resident pane roles (`director` / `pm` / `devm` / `anam` / `devtl` / `anatl`) all load **`cbc-herdr`** (CodeBuddy status reporting inside herdr); engineer sub-agents occupy no pane and do not need it.

| Role | Deliverables (landing location) |
|---|---|
| `director` | `docs/team.md`; `docs/handoff/` when needed; review conclusions (inbox); GitLab pushes (one per ticket + hourly patrol); device installation |
| `pm` | PRD in `docs/pd/prd/`, SPEC in `docs/pd/spec/`, tickets in `docs/dev/tickets/`, `docs/human/human-arch/`, `docs/human/human-plan/` |
| `devm` | "Implementation status" appended at the end of each ticket; merged mainline code; acceptance evidence (reported through the inbox) |
| `devtl` | Implementation-level first-pass report (`inbox/devm/`); commits on the `feat/{ticket-id}` branch |
| `anam` | Research report in `docs/analyst/` + primary evidence in `docs/analyst/evidence/` |
| `anatl` | Evidence-gathering report and primary sources (`inbox/anam/`) |
| `dev-e` / `ana-e` / `pm-e` | Worktree code commits / evidence material / verification material (closed out by whoever spawned them) |

**Three-layer naming**: the skill name carries the `dmt-` prefix (`dmt-director` / `dmt-pm` / `dmt-dm` / `dmt-am` / `dmt-dtl` / `dmt-atl`) and is used by the skill registry, the install directory and the slash command; the runtime id carries no prefix (`director` / `pm` / `devm` / `anam` / `devtl{n}` / `anatl{n}` / `dev-e` / `ana-e` / `pm-e`) and is used by pane labels, inbox directories and direction codes; prose and logs use the form of address (Director / Development Manager / Analysis Manager / Development Lead {n} / Analysis Lead {n}). **Never mix the three.**

**Single-line command**: each role talks only to its direct superior and direct reports; the director never skips levels to leads or engineers, leads never talk to each other, managers never talk sideways, and every cross-department matter is relayed by the director. **Engineers are always sub-agents** (no pane, no cross-pane communication): below the threshold the manager spawns them, above it the lead does (`devm` 4 / `anam` 2) — there is no pane-level channel between a manager and an engineer, only a parent-child sub-agent relation; `pm-e` is spawned by `pm` directly.
Leads are **spawned on demand and closed when done**: a manager **only when its queued tasks exceed the threshold (`devm` >4, `anam` >4)** runs `herdr pane split "$HERDR_PANE_ID" --direction right --cwd "$PWD" --no-focus` inside **its own tab**, then `herdr pane rename <pane> devtl{n}` (anam does the same with `anatl{n}`), starts the harness on its behalf (`codebuddy --permission-mode auto`) and types `/dmt-dtl` / `/dmt-atl` to load the lead skill; once the batch is closed out and no next batch can be assigned, **the creator itself** closes it with `herdr pane close <pane>` (the `pane` resolved by **pane label** from `herdr pane list`). **Three preconditions for closing** (report booked, worktree removed with `git worktree remove`, no unread inbox message from that lead) are fixed in order and none is optional; **never close before collecting** (closing the pane terminates that agent session and the context cannot be recovered); **`herdr tab close` is forbidden** (the lead shares the manager's tab, so closing the tab kills the manager too); **reusable within a batch, never carried across batches**; a non-creator must not close on someone's behalf. Details in `team.md` §1.2.

Members run inside Herdr (a terminal multiplexer for multi-agent work) and **identify peers by pane label** (the label equals the role name and is unique in the workspace; never by position inside a tab, and pane ids are re-resolved before every send).
**Inter-role communication = inbox file + herdr doorbell**: the body goes into the receiver's `inbox/<recipient>/{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (project root, not under `docs/`), and herdr only carries one line ("you have a new message …"); the receiver **sends no receipt**: it first moves the file into `inbox/<self>/.doing/` with `msg-take.sh` (claim), then deletes it with `msg-done.sh` once done (details in `team.md` §1.3).
Workflow in one line: the director fixes the acceptance criteria → anam does the research (reviewed by the director) + pm writes the PRD, SPEC and tickets and self-reviews at the document gate (the director only confirms the requirement reading) → devm takes the tickets and schedules them, self-dispatching dev-e or opening a lead pane by queue depth → the lead spawns dev-e to implement and does the first pass → devm reviews (code gate) and integrates → the director spot-checks and runs `git push` (at least one push per ticket, hourly patrol of unpushed changes). Installation (`adb install` etc.) and `git push` **are performed by the director only**.

**Team contract (the single authority on organization, communication, file naming, directory ownership and discipline) = [`dmt-director/team.md`](dmt-director/team.md).**

```
dmt/                              # one folder per role
├── README.md                                 # project overview (this file)
├── dmt-director/                             # Director (skill director)
│   ├── SKILL.md
│   ├── team.md                         # team contract (single authority)
│   ├── README.md                       # pointer: root README.md
│   └── scripts/                        # checker / file claims / init / team setup / spawn lead / close lead / send message / publish / install
├── dmt-pm/SKILL.md                      # Product department manager (pm)
├── dmt-dm/SKILL.md                      # Development manager
├── dmt-am/SKILL.md                      # Analysis manager
├── dmt-dtl/SKILL.md                     # Development team lead (devtl{n})
└── dmt-atl/SKILL.md                     # Analysis team lead (anatl{n})
```

## Installing into a project

The folder name in this repo is the skill name (`dmt-director` / `dmt-pm` / `dmt-dm` / `dmt-am` / `dmt-dtl` / `dmt-atl`); **when installing into a skill directory, copy under the same name**. The runtime ids (`devm` and friends) only label panes and inbox folders and do not change with the skill name.

```bash
# symlink install (recommended; follows updates from this repo)
bash dmt-director/scripts/install-skills.sh <project-root>

# copy install (the target project does not follow this repo)
bash dmt-director/scripts/install-skills.sh <project-root> --copy
```

The script does five things: creates `.agents/skills/` and `scripts/`; symlinks or copies the six skill directories; copies `team.md` to `docs/team.md`; copies `scripts/*.sh` into the project's `scripts/`; and calls `init-project.sh` to create the directories, write `.gitignore` and run the machine check.

Symlinking the whole role directory exposes the contract, the README and the checker script under `dmt-director/` without affecting skill loading.
When installing into a user-level skill directory of another harness (codebuddy / codex / opencode …), the rule is the same: **the folder name is the skill name**.

## Checker

```bash
bash dmt-director/scripts/check-dmt-doc-paths.sh <project-root>   # checks the current directory when the argument is omitted
# override with DMT_SKILLS_DIR when the skills are not under <project-root>/.agents/skills (default on line 9 of the script)
```

**Seventeen** criteria: ① the six artifact directories + the root `inbox/` exist (**the director fills gaps at initialization**, see `team.md` §3.1); ② the six skills (`dmt-director` / `dmt-pm` / `dmt-dm` / `dmt-am` / `dmt-dtl` / `dmt-atl`) each point at their own unique directory (PRD / SPEC / tickets / human documents belong to `dmt-pm`); ③ **the lead-instance close action is registered** (the contract and the `dmt-dm` / `dmt-am` skills contain `close-leader.sh`, and the contract says "only panes may be closed"); ④ **identity resolution is registered** (the contract and all six skills contain `pane label`); ⑤ **the lead-tier parallelism criterion is registered** (`dmt-dtl` / `dmt-atl` contain "must run in parallel", and the contract says "≥2 ⇒ must be dispatched concurrently"); ⑥ **the manager-tier path criterion and saturated dispatch are registered** (`dmt-dm` contains "≤4" and ">4", `dmt-am` contains "≤4" and ">4", and the contract contains "≤4 ⇒ derive `dev-e` itself" and "≤4 ⇒ derive `ana-e` itself" plus "concurrency = number of units", and `dmt-dm` / `dmt-am` contain "saturat" and `teammate`); ⑦ **install and push ownership is registered** (the contract contains "only the director", `dmt-director` contains `git push`, `dmt-dm` contains "does not push", and the contract contains "at least hourly"); ⑧ **the mattpocock mandatory skills are registered per role** (the contract contains "mandatory" and the role table, and each of the six skills contains its own mandatory skill names); ⑨ **file claims are registered** (the contract contains "file claims" and `file-claim`, each of the six role skills contains `file-claim`, and the script exists); ⑩ **review gate ownership is registered** (the contract and `dmt-pm` contain "document gate", the contract and `dmt-dm` contain "code gate", and `dmt-director` contains "does not replace"); ⑪ **the cbc-herdr common skill is registered** (each of the six pane-role skills contains `cbc-herdr`); ⑫ **skill links match upstream** (the contract and all six skills contain `raw.githubusercontent.com`); ⑬ **deterministic actions are scripted** (fourteen scripts exist and are executable); ⑭ **the three-state inbox is registered** (the contract contains `.doing/` and `.seq`, and each of the six skills contains `msg-take.sh`); ⑮ **dispatch-first and the concurrency ledger are registered** (the contract and `dmt-pm` / `dmt-dm` / `dmt-am` contain "dispatch first" and "concurrency ledger"); ⑯ this contract is fully registered; ⑰ negative samples are rejected (**only the §3 landing registry table** is inspected; historical traces in §8 do not count). **Rerun after changing the path convention, pane lifecycle, parallelism wording, role hierarchy, write permissions, mandatory skills, file claims, review gates, common skills, skill links, inbox lifecycle or script interfaces.**

## Maintenance

- This repo is the **single maintenance point** for dmt; consumers keep no copy. With symlinks, skills and the contract update with the repo and take effect immediately (no reinstall needed).
- Contract references inside the skills do not depend on relative paths (written as "`dmt-director/team.md` (this repo; `docs/team.md` once installed)"), so symlink installs never break.
- A change to a script interface (arguments, output, exit codes) counts as a contract change and must be mirrored in the six skills and in checks 4j / 4k.
- Harness-side skills required: `herdr` (pane control and label resolution), `cbc-herdr` (CodeBuddy status reporting), `pi-subagents` (pi harness only; cbc uses Agent/team sub-agents), plus mattpocock's [`/to-spec`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-spec/SKILL.md), [`/to-tickets`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-tickets/SKILL.md), [`/code-review`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/code-review/SKILL.md), [`/tdd`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/tdd/SKILL.md), [`/research`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/research/SKILL.md) and friends (installation and fallback in `team.md` §1.4).
