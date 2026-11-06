# dmt

The role-skills repo of the dmt team: **the single place where the team definition and the seven role skills are maintained**. Hierarchy: `director` (Director, also head of the product unit) → department managers (`devm` / `anam`) → engineers (`dev-e` / `ana-e` / `pde{n}` / `reviewer{n}`).
**The product unit is folded into the director**: when writing a PRD / SPEC / ticket, the director summons `pde{n}` to do the writing (human-facing docs are written by the director in person), and spawns `pde{n}` / `reviewer{n}` subagents itself (`dmt-pde` / `dmt-reviewer` skills; they occupy no tab and no pane). There is no product-manager role; the `devm` pane sits on the right of the director tab, and `anam` gets its own tab.
**Managers dispatch engineers directly**: `devm` / `anam` always dispatch `dev-e` / `ana-e` subagents directly (independent tasks are launched fully in parallel, up to the harness concurrency limit); creating worktrees, the first-pass implementation review, and the first-hand source check are closed out by the manager — **there is no team-lead layer**.

> **Scope (must read)**: all discipline in this repo — role permissions, **ownership of write operations (hardware-device writes / `git push` / merge)**, gates, pane lifecycle, inbox conventions — **applies only to the "target project" governed by the dmt workflow** (the project root initialized with `init-project.sh <project-root>`).
> **It does not apply when maintaining the skill repos themselves, such as `dmt` / `dmt-en`**: a maintainer (human or another agent) may `git add` / `git commit` / `git push` directly, **with no director authorization and no need for devm to push on their behalf**.

| Role | Skill name | Runtime id (pane label) | Direct superior | Direct reports | Responsibility summary |
|---|---|---|---|---|---|
| Director, also head of the product unit | `dmt-director` | `director` | User | `devm`, `anam` (+ the `pde{n}` / `reviewer{n}` side track it spawns) | Sole entry point; receives requirements and acceptance criteria, summons `pde{n}` to write the PRD / SPEC / tickets (the director finalizes them), writes the human-facing docs and issues the document-gate verdict, dispatches work, arbitrates, maintains panes/tabs; spot-check release (merge / push belong to devm; **hardware-device writes may be done by either devm or the director**; **the main code-acceptance track is devm dispatching `reviewer{n}`**, while **the director runs a side track of self-spawned `reviewer{n}` for spot checks and high-risk re-verification**); **does not replace** devm's code review |
| Product engineer (subagent) | `dmt-pde` | `pde{n}` | `director` | — | **Writes the PRD / SPEC / tickets**, gathers product facts, enumerates user stories and boundaries, checks acceptance criteria; **occupies no tab and no pane**; spawned by the director, one instance per unit |
| Development manager | `dmt-dm` | `devm` | `director` | `dev-e` / `reviewer{n}` (subagents) | Works directly on user requests and the tickets plan (just keep the director informed), schedules and dispatches work, creates worktrees, dispatches `dev-e` to implement, takes the diff and does the first-pass implementation review, **code gate** (owner of ticket code review), **dispatches `reviewer{n}` for independent acceptance** (independent of the implementer, evidence-based), integrates deliverables, **merge / push (the codebase is managed by devm; merge / push as soon as `reviewer{n}` passes)**; **hardware-device writes (either devm or the director)**; **does not split tickets** |
| Analysis manager | `dmt-am` | `anam` | `director` | `ana-e` (subagent) | Works directly on user requests and the tickets plan (just keep the director informed); splits sub-problems, dispatches `ana-e` for parallel evidence gathering, checks first-hand sources, closes out research reports |
| Development engineer (subagent) | `dmt-de` | `dev-e` | `devm` | — | One worktree per ticket, TDD implementation (`/tdd` `/implement`), self-review before committing (`/code-review`), commit inside the worktree (no push) |
| Analysis engineer (subagent) | `dmt-ae` | `ana-e` | `anam` | — | First-hand evidence (`/research`), competitor reverse-engineering (`/rea`), evidence grading, cross-examination (`/grilling` family) |
| Review engineer (subagent) | `dmt-reviewer` | `reviewer{n}` | **Two tracks**: main track `devm` / side track `director` | — | On the **main track**, devm dispatches it per ticket to do **code review** (ticket-by-ticket code acceptance, independent of `dev-e`); on the **side track**, the director spawns it for **spot checks / high-risk re-verification** (at least 1 ticket sampled per batch, 100% of high-risk tickets, instances independent of the main track); `/code-review` is written into the dispatch prompt; evidence-based, does not change code, does not push |

**Role × mandatory skills** (mattpocock, must be used) and their per-item purposes are in `dmt-director/team.md` §1.4 (with clickable links).

Skill names are **character-for-character identical** to the [`mattpocock/skills`](https://github.com/mattpocock/skills) upstream, and the links point to the `raw.githubusercontent.com` source files; `/rea` belongs to REA and is not in that repo, so it keeps its original name.

Also: the three pane-resident roles (`director` / `devm` / `anam`) all load **`cbc-herdr`** (CodeBuddy status reporting in herdr); engineer subagents occupy no pane and do not need it.

| Role | Deliverables (where they land) |
|---|---|
| `director` | `docs/team.md`; `docs/pd/prd/` PRDs, `docs/pd/spec/` SPECs, `docs/dev/tickets/` tickets, `docs/human/human-arch/`, `docs/human/human-plan/` (PRDs / SPECs / tickets are written by `pde{n}` and finalized by the director; pde instances doing evidence gathering deliver evidence only and write nothing to disk); `docs/handoff/` as needed (director / devm); spot-check / re-verification verdicts (inbox); **hardware-device writes (shared with devm)** |
| `devm` | "Implementation status" at the end of the ticket; the merged mainline code; `feat/{ticket-id}` branch commits (worktree); first-pass implementation review verdict; `reviewer{n}`'s per-item acceptance verdicts; **merge and push**; **hardware-device writes (either devm or the director)**; GitLab push (one push per ticket + hourly patrol) |
| `anam` | `docs/analyst/` research reports + `docs/analyst/evidence/` first-hand evidence; evidence reports and first-hand source checks |
| `pde{n}` | Writes `docs/pd/prd/`, `docs/pd/spec/`, `docs/dev/tickets/` (the director finalizes) |
| `reviewer{n}` | Per-item acceptance verdicts (main track reports to `devm`, side track to `director`; **does not write to disk and does not use the inbox**, though side-track spot-check verdicts may be written to `docs/handoff/`) |
| `dev-e` / `ana-e` | Worktree code commits / verification material (closed out by the spawner, does not write to the inbox) |

**Three-layer naming**: skill names carry a `dmt-` prefix (`dmt-director` / `dmt-dm` / `dmt-am` / `dmt-pde` / `dmt-de` / `dmt-ae` / `dmt-reviewer`) and are used for the skill registry, install directories, and slash commands; runtime ids carry no prefix (`director` / `devm` / `anam` / `pde{n}` / `dev-e` / `ana-e` / `reviewer{n}`, with `{role}-helper` for helpers) and are used for pane labels, inbox directories, and direction codes; body text and logs use the role titles (Director / Development Manager / Analysis Manager). **The three layers are never mixed.**

**Single-line command**: each role communicates only with its immediate superior and direct reports; the director does not command engineers across levels, managers never connect laterally, and all cross-department traffic is routed through the director. **Engineers are always subagents** (no pane, no cross-pane messaging): they are always opened directly by a manager (`devm` opens `dev-e`, `anam` opens `ana-e`; independent tasks are launched fully in parallel, up to the harness concurrency limit) — there is no pane-level channel between a manager and an engineer, only a parent-child agent relationship; `pde{n}` is opened directly by the `director`.
**helper (`{role}-helper`, a pure clone of the principal, at most one per role)**: `director-helper` / `devm-helper` / `anam-helper` are **pure clones** of their principals — the task is delivered **once, at spawn**, and after that the helper **accepts no input from the input box**; results are written back to the principal **one-way** by `helper-report.sh` (`inbox/<principal>/`, no doorbell); a helper **has no inbox of its own** (it receives nothing). **The only observable criterion for opening one**: this pane has `agent_status == working` and has had a pending item unhandled for more than 10 minutes. **Its lifecycle is maintained by its creator (the principal role)**: create it with `bash dmt-director/scripts/spawn-helper.sh <director|devm|anam>` (idempotent, supports `--dry-run` / `--no-start`; the helper tab label is fixed to `helper` (shared by the whole team), the pane label is fixed to `{role}-helper`, and it starts the harness and loads the **skills of the same role**), self-heal and rename on label drift, and reclaim it when the task is done with `bash dmt-director/scripts/close-helper.sh <director|devm|anam>` (supports `--force` / `--dry-run`; **the helper tab is kept and reused, it does not close with the pane**). **Exclusive actions are never delegated**: hardware-device writes (`devm` / `director` principals) and merge / push (`devm` principal) are never handed to a helper.

Members run inside Herdr (a terminal multi-agent multiplexer) and **identify partners by pane label** (the label matches the role name and is unique across the whole workspace; position within a tab is irrelevant, and the pane id is re-checked before every send).
**Inter-role communication = inbox file + herdr doorbell**: the body is written to the recipient's `inbox/<recipient-role>/{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (in the project root, not under `docs/`), and herdr only sends a single line "you have a new message …"; the recipient **never acknowledges receipt**: it first runs `msg-take.sh` to move the file to `inbox/<self>/.doing/` (claiming it), and `msg-done.sh` to delete it when done (see `dmt-director/ops/comms.md`).
The workflow in one sentence: anam does research (reviewed by the director) → the director sets the acceptance criteria and summons `pde{n}` to write the PRD, SPEC, and tickets (document gate self-assessment) → devm takes the tickets and schedules them, **devm / anam dispatch engineer subagents directly (independent tasks fully in parallel, up to the harness concurrency limit), and the manager closes out the first-pass implementation review and the source check** → devm completes the ticket and does the code-gate review → **devm dispatches reviewer1…reviewer{n} per ticket count** (skill `dmt-reviewer`; independent of the dev-e that implemented that ticket, evidence-based) to accept item by item against the SPEC + ticket of the same spec-seq → **once it passes, devm merges/pushes directly** (reviewer{n} is a subagent, occupies no pane, and loads no skills; `/review` (= `/code-review`) is written into the dispatch prompt; merge and push belong to devm alone: push at least once per completed ticket and patrol unpushed changes at least hourly, and the codebase is managed by devm) — if it fails, it is bounced back to **dev-e** for rework, with no merge/push beforehand; **the director retains spot checks and high-risk re-verification**. merge / push **belong to `devm` alone**; **hardware-device writes may be done by either `devm` or the `director`**. devm / anam may **work directly on user requests and the tickets plan**, only needing to inform the director; the director **lets it through by default and only steps in if they judge it inappropriate** (unobstructed).

**The team contract (the single authority on organization, communication, file naming, directory responsibilities, and discipline) = [`dmt-director/team.md`](dmt-director/team.md).**

```
dmt/                                    # one folder per role
├── README.md                           # project overview (this file)
├── dmt-director/                       # Director (skill dmt-director)
│   ├── SKILL.md
│   ├── team.md                         # team contract (normative layer, the single authority)
│   ├── OPS.md                          # operations-manual compatibility entry (routes to ops/ by task)
│   ├── ops/*.md                        # operations manuals (runtime / comms / file-claim / helper / permission-notes)
│   ├── harness/                        # loaded per harness (COMMON.md + one delta file each for pi/codebuddy/claude/codex/opencode)
│   ├── CHANGELOG.md                    # detailed change history (all 87 entries; earlier quarters archived in changelog/)
│   ├── harness_matrix.yaml             # harness compatibility matrix (install paths / prefixes / launch commands / concurrency limits; single source)
│   ├── dmt_contract.yaml               # structural contract (skill inventory / version source / directories / scripts; single source)
│   ├── hooks/pre-commit                # git hook: blocks intranet addresses / credentials / .env from being committed
│   ├── README.md                       # script inventory (see the root README.md for the prose)
│   └── scripts/                        # machine checks (prose + structure) / file claims / init / one-shot launch / team creation / helper creation / helper reporting / helper shutdown / messaging / claiming / closing / pushing / install / hook install / version sync / CHANGELOG archiving / reviewer health gate / harness matrix read / harness detection (+ lib-dmt.sh shared library)
├── dmt-pde/SKILL.md                    # product engineer (pde{n} subagent skill, no pane)
├── dmt-de/SKILL.md                     # development engineer (dev-e subagent skill, no pane)
├── dmt-ae/SKILL.md                     # analysis engineer (ana-e subagent skill, no pane)
├── dmt-reviewer/SKILL.md                    # review engineer (reviewer{n} subagent skill, no pane)
├── dmt-dm/SKILL.md                     # development manager
├── dmt-am/SKILL.md                     # analysis manager
└── logs/                              # incident post-mortems (e.g. 2026-10-27-serial-queue-incident.md)
```

## Installing into a project

The directory name inside the repo is the skill name (`dmt-director` / `dmt-dm` / `dmt-am` / `dmt-pde` / `dmt-de` / `dmt-ae` / `dmt-reviewer`), and **installing into a skills directory copies it under the same name**. Runtime ids (`devm`, etc.) are only pane labels and inbox names, and do not change with the skill name.

```bash
# Symlink install (recommended; follows updates of this repo); the default --harness all ⇒ covers .agents/skills + .claude/skills + .codebuddy/skills
bash dmt-director/scripts/install-skills.sh <project-root>

# Copy install (the target project does not follow this repo)
bash dmt-director/scripts/install-skills.sh <project-root> --copy

# Install only the locations of the specified harness (narrowing; default is all)
bash dmt-director/scripts/install-skills.sh <project-root> --harness claude,codebuddy
```

The script does four things: ① **creates the skill locations per harness** and symlinks or copies the seven skill directories (default `--harness all` ⇒ three places, `.agents/skills/` + `.claude/skills/` + `.codebuddy/skills/`, covering five harnesses); ② links or copies the whole `dmt-director/` (including `scripts/`) into the project root; ③ **symlinks** `team.md`, `OPS.md`, and `ops/` into `docs/` (copied instead in `--copy` mode); ④ calls `init-project.sh` to create directories, write `.gitignore`, and run the machine checks.

> **Why three locations (measured with per-harness probes on 2026-11-04)**: each harness **only recognizes its own skills directory**, and there is no "one place fits all" — `codex` / `opencode` / `pi` read `.agents/skills/` (`pi`'s project-level directory requires `--approve`), `claude` reads **only** `.claude/skills/`, and `codebuddy` reads **only** `.codebuddy/skills/`. That is why `install-skills.sh` defaults to all three; installing only one location silently fails on claude / codebuddy. See `dmt-director/team.md` §1.2 for details.

When you symlink a whole role directory, the contracts, docs, and machine-check scripts inside `dmt-director/` are visible too, which does not affect skill loading.
When installing into a user-level skills directory of another harness, the rule is the same: **the directory name is the skill name**.

**Skill discovery directories of the five harnesses (measured with per-harness probes on 2026-11-04)**: `.agents/skills/` is **not** their intersection — measured, only `codex` / `opencode` / `pi` read it, while `claude` and `codebuddy` **only recognize their own private directories** (project-level `.claude/skills/` / `.codebuddy/skills/`, user-level `~/.claude/skills/` / `~/.codebuddy/skills/`). So the `<target>/.agents/skills/` location of `install-skills.sh` covers only those three (`pi` additionally needs `--approve`); **when installing for claude / codebuddy you must also symlink their private directories**. Another easy mistake: `pi`'s user-level private directory is `~/.pi/agent/skills/` (**not `~/.pi/skills/`**), and `opencode`'s project-level directory is `.opencode/skills/` (**plural**). **The slash syntax differs too**: claude / codebuddy / codex / opencode use `/dmt-dm`, while **pi uses `/skill:dmt-dm`** — the launch scripts generate this automatically through `dmt_skill_cmd` in `lib-dmt.sh`, so do not type it by hand. For the full table (including project-level / user-level), see `dmt-director/team.md` §1.2 "harness compatibility".

**Alternative Codex launch**:

```bash
bash dmt-director/scripts/setup-team.sh --harness codex
```

Codex receives the role skills and helper tasks in a single delivery with the first-round prompt; mattpocock plugin skills use `mattpocock-skills:<name>`. After confirming trust manually the first time, run `setup-team.sh --harness codex --force-start`. When Codex has no `spawn_agent` in a herdr pane, it only does the work of its own pane role; it will not fake nested panes or `codex exec` subagents. See `dmt-director/ops/runtime.md` "Codex differences" for details.

## Machine checks

```bash
bash dmt-director/scripts/check-dmt.sh <project-root>   # single entry point: structural assertions + content assertions
# if the skills are not installed under <project-root>/.agents/skills, override with DMT_SKILLS_DIR
# when maintaining the dmt repo itself (the canonical skills are at the repo root, not in .agents/skills):
DMT_SKILLS_DIR="$PWD" bash dmt-director/scripts/check-dmt.sh "$PWD"
```

**A structural assertions + B content assertions**, with all facts coming from a single source: `dmt-director/dmt_contract.yaml` (skill inventory / version source / directories / organization / scripts / operations manuals / skill budget / **content_assertions**) and `dmt-director/harness_matrix.yaml` (the five-harness matrix) — adding or changing an assertion means editing only the YAML, no more scattered Chinese greps. **Per-item descriptions and criteria are maintained in `dmt-director/team/09-check.md` (single source)**.

## Intranet endpoint configuration (`.env`)

Intranet addresses (GitLab, local reviewer endpoints, etc.) are **never written into the repository prose**; they are always referenced by variable name, with the values in `.env`:

```bash
cp .env.example .env && ${EDITOR:-vi} .env   # fill in the actual addresses for this machine
```

| Variable | Purpose |
|---|---|
| `DMT_GITLAB_SERVER` / `DMT_GITLAB_PORT` / `DMT_GITLAB_REPO` | Intranet GitLab (the push target of devm's `publish.sh`) |
| `DMT_LOCAL_MODEL_HOST` / `DMT_LOCAL_MODEL_PORT` | Local reviewer (`autoModeClassifier`) endpoint host / port (assembled into `http://<host>:<port>/v1/models`) |
| `DMT_AUTO_REVIEW_LOCAL_MODEL` | Local reviewer model id |

- `.env` is read by `dmt_load_env` in `dmt-director/scripts/lib-dmt.sh` (lookup order: `$DMT_ENV_FILE` → `<project-root>/.env` → skill-repo root `.env`); **already-exported environment variables take precedence**, and `.env` does not override them. Use `DMT_ENV_FILE=<path>` to point at a different file.
- `.env` is **not committed** (see `.gitignore`); the template is `.env.example`. `DMT_AUTO_REVIEW_URL` can supply the whole endpoint URL directly, overriding the host / port assembly.

## Maintenance

- **Single source**: team constants live only in `dmt-director/team.md`; operational details are routed from `dmt-director/OPS.md` into `ops/`; the harness's **machine facts** live only in `harness_matrix.yaml`, and the **skill-loading descriptions** only in `dmt-director/harness/` (one shared file + one delta file per harness); structural facts live only in `dmt_contract.yaml`. The seven skills describe only "how this role works", and all harness differences are written as pointers.
- **Version sync**: the authoritative version number is in `dmt_contract.yaml`; `bash dmt-director/scripts/bump-version.sh <X.Y.Z>` refreshes team.md and the seven SKILL.md files in one command, and `--check` verifies they carry the same number.
- **Leak-prevention gate**: `bash dmt-director/scripts/install-git-hooks.sh` enables the version-controlled `pre-commit` hook (blocks `.env`, intranet addresses, and key-like strings); `launch.sh` installs it by default. Bypass a false positive with `git commit --no-verify`.
- **Change history**: `CHANGELOG.md` keeps only the current quarter's entries; `bash dmt-director/scripts/archive-changelog.sh` archives earlier quarters verbatim into `dmt-director/changelog/<YYYYQn>.md`.

- This repo is the **single maintenance location** for dmt. Skill locations (`<role>/` under `.agents/skills/`, `.claude/skills/`, `.codebuddy/skills/`, laid down by `install-skills.sh` according to `--harness`) and **`docs/team.md` / `docs/OPS.md` / `docs/ops/` are all installed as symlinks** (default `link` mode) ⇒ they follow updates of this repo and take effect immediately after a change, **with no need to re-run the install**. Only projects installed with `--copy` do not follow this repo.
- Contract references inside the skills do not rely on relative paths (they are written as "`dmt-director/team.md` (this repo; `docs/team.md` once installed into a project)"), so symlink installs do not break the links.
- **Repository relationship (updated 2026-11-06)**: this repo (`dmt-en`) is the **English mirror**, synchronized to upstream `dmt` **`5.18.7`** (seven skills + the `harness/` layer + machine check). The Chinese repo `dmt` is authoritative; when the two differ, `dmt` wins and this mirror is re-synchronized from it — the two are no longer maintained independently.
- Changes to script interfaces (arguments, output, exit codes) count as contract changes and must be synced to the seven skills and check 4m.
- Dependency on harness-side skills: `herdr` (pane control and label identification), `cbc-herdr` (CodeBuddy status reporting only), `pi-subagents` (pi harness only; Codex uses native `spawn_agent`/`wait_agent`, cbc uses Agent/team subagents), plus mattpocock's [`/to-spec`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-spec/SKILL.md), [`/to-tickets`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-tickets/SKILL.md), [`/code-review`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/code-review/SKILL.md), [`/tdd`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/tdd/SKILL.md), [`/research`](https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/research/SKILL.md), and so on (see `team.md` §1.4 for installation and fallback).
