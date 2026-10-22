# dmt Team Contract

> This file is the **single team definition for dmt**: organization, members, communication, file naming, workflow, directory ownership and discipline. The five role skills `director` / `dev-m` / `ana-m` / `dev-tl{n}` / `ana-tl{n}` are implementation notes only; **this file wins on any conflict**.
> Team members run inside Herdr, a terminal multiplexer for AI agents. Sessions and panes change across restarts; this file does not record pane ids.

## 0. Repository layout

The repository root holds one folder per role. The team contract, the repo README and the path checker live with the director under `director/`, not loose at the root:

```
dmt/
├── director/                             # Director, also product manager (skill director)
│   ├── SKILL.md                          # role skill
│   ├── team.md                           # team contract (this file, single authority)
│   ├── README.md                         # repo notes and installation
│   └── scripts/check-pda-doc-paths.sh    # output-path checker
├── dev-m/SKILL.md                        # Development manager (dev-m)
├── ana-m/SKILL.md                        # Analysis manager (ana-m)
├── dev-tl/SKILL.md                       # Development team lead (dev-tl{n})
└── ana-tl/SKILL.md                       # Analysis team lead (ana-tl{n})
```

## 1. Team definition

### 1.1 Organization and members

**Four levels**: `director` (director) → department manager (`dev-m` / `ana-m`) → team lead (`dev-tl{n}` / `ana-tl{n}`) → engineer (`dev-e` / `ana-e`). Five role skills, strictly four levels.

```
director            Director (team lead + product manager, label director)
├── dev-m               Development manager (label dev-m)
│   ├── dev-tl1         Development team lead (label dev-tl1)
│   │   ├── dev-e       Development engineer (sub-agent, no tab)
│   │   └── dev-e ...
│   ├── dev-tl2 ...
│   └── dev-tl{n}
└── ana-m               Analysis manager (label ana-m)
    ├── ana-tl1         Analysis team lead (label ana-tl1)
    │   ├── ana-e       Analysis engineer (sub-agent, no tab)
    │   └── ana-e ...
    └── ana-tl{n}
```

| Role | Full name | Skill / instance | tab label | Reports to | Direct reports | Responsibility |
|---|---|---|---|---|---|---|
| Director (team lead + product manager) | TeamLeader + ProductManager | `director` | `director` | User | `dev-m`, `ana-m` | Single user entry point; take requirements, set acceptance criteria, write PRD and SPEC personally, review research reports and ticket code, arbitrate across departments |
| Development manager | DevelopManager | `dev-m` | `dev-m` | `director` | `dev-tl{n}` | Split the SPEC into tickets, spawn development team leads on demand, integrate and accept, push only after director review |
| Analysis manager | AnalystManager | `ana-m` | `ana-m` | `director` | `ana-tl{n}` | Take research requests, spawn analysis team leads on demand, consolidate research reports |
| Development team lead | DevelopLeader | `dev-tl{n}` | `dev-tl{n}` | `dev-m` | `dev-e` (sub-agent) | Create the worktree, dispatch development engineers, review the diff and run the implementation-level check, report to dev-m |
| Analysis team lead | AnalystLeader | `ana-tl{n}` | `ana-tl{n}` | `ana-m` | `ana-e` (sub-agent) | Split sub-questions, dispatch analysis engineers in parallel, verify primary sources, report to ana-m |

**Single-line command (hard rule; no role may skip a level or connect sideways):**

1. `director` commands **only** `dev-m` and `ana-m`; **must not** task or receive from `dev-tl{n}` / `ana-tl{n}` / engineers directly.
2. `dev-m` commands **only** `dev-tl{n}`; **must not** task `dev-e` directly, nor receive dev-e reports directly.
3. `ana-m` commands **only** `ana-tl{n}`; **must not** task `ana-e` directly, nor receive ana-e reports directly.
4. A team lead reports **only** to its own department manager. `dev-tl{n}` and `ana-tl{n}` never connect to each other, nor do dev-m and ana-m; cross-department matters go through `director`.
5. Engineers `dev-e` / `ana-e` report **only** to the team lead that spawned them; they carry **no standalone skill** and **no cross-tab communication** (discipline lives in the team lead's dispatch prompt).

### 1.2 Runtime and tab lifecycle

- Every role runs inside **Herdr**, each occupying one tab.
- Peers are identified **by tab label** (`herdr tab list`), **never by remembered pane id**: pane ids drift across restarts and moves.
- Startup order: prepare the `director` tab from the user session (or outside it); **the director creates the `dev-m` and `ana-m` tabs** and asks the user to start each harness inside its tab.
- **Team leads are spawned on demand, never pre-created**: `dev-m` creates `dev-tl{n}` and `ana-m` creates `ana-tl{n}` at the point of need. `{n}` increases monotonically from 1; **a closed number is never reused**.

```bash
# 1) list labels (match on label text, never copy a historical id)
HERDR_ENV=1 herdr tab list --workspace "$HERDR_WORKSPACE_ID"
# 2) resolve the tab_id from the label, then read that tab's current pane id
HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID"
```

If the target label is absent: **stop and ask the user**. Do not guess a pane id and do not retry against a session that does not exist.

Create a tab (director creates managers; managers create team leads):

```bash
# <ROLE> is dev-m / ana-m; the director's own tab is created by the user, never by the director session
HERDR_ENV=1 herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label <ROLE>

# team leads: dev-m creates dev-tl{n}, ana-m creates ana-tl{n} (n from 1 upward)
HERDR_ENV=1 herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label dev-tl1
```

After creating a tab, the creator must bring it into role: if the harness does not start automatically, **ask the user to start it**; once started, deliver the first task (role name, skill name, manager's label, task file path) into that tab and verify delivery.

### 1.3 Communication (inbox file + herdr doorbell)

**All bodies travel as files; herdr carries one doorbell line only.** Dispatch, reports, review verdicts, arbitration requests and defect returns all become a file in the receiver's inbox first, then herdr rings once with "you have a new message <file>". **Never paste long bodies, logs or diffs into the message.**

**Direct communication is allowed only along the reporting line** (everything else is relayed by the manager):

| From | To | Direction code |
|---|---|---|
| `director` | `dev-m` / `ana-m` | `director2dev-m` / `director2ana-m` |
| `dev-m` / `ana-m` | `director` | `dev-m2director` / `ana-m2director` |
| `dev-m` | `dev-tl{n}` | `dev-m2dev-tl{n}` |
| `dev-tl{n}` | `dev-m` | `dev-tl{n}2dev-m` |
| `ana-m` | `ana-tl{n}` | `ana-m2ana-tl{n}` |
| `ana-tl{n}` | `ana-m` | `ana-tl{n}2ana-m` |

**Step 1 — locate the peer** (re-resolve every time; never reuse a pane id): `herdr tab list` gives the `tab_id` for the label → `herdr pane list` gives the **current** pane id for that `tab_id`. Label missing ⇒ **stop and ask the user**; do not guess a pane id.

**Step 2 — write the inbox file**

- Path: `inbox/<recipient>/{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` at the **project root** (`<recipient>` ∈ `director` / `dev-m` / `ana-m` / `dev-tl{n}` / `ana-tl{n}`; **not under `docs/`**; `mkdir -p` if missing).
- `{seq}`: per-sender running number from 001, one number per message (unrelated to the SPEC `spec-seq`).
- `{direction}`: from the table above; cross-department traffic is relayed by the director, so `dev-m2ana-m` / `dev-tl2ana-tl` never appear.
- `{slug}`: short lowercase English with hyphens, at most 5 words.
- `{YYMMDDHHMM}`: timestamp at write time, two-digit year + month + day + hour + minute, no separators (e.g. `2610201430`).
- Body is **self-contained**: one-line summary / authoritative document paths / requested action / expected output / reporting requirements.

**Step 3 — ring the doorbell** (pick the channel by the **peer harness**; the message is one line: file name + folder):

| Peer harness | Doorbell |
|---|---|
| pi-coding-agent / codex / opencode | `HERDR_ENV=1 herdr agent prompt <pane or registered agent name> 'you have a new message {file}, in inbox/<recipient>/'` |
| codebuddy (cbc) | `HERDR_ENV=1 herdr pane send-text <pane> 'you have a new message {file}, in inbox/<recipient>/'` followed by `HERDR_ENV=1 herdr pane send-keys <pane> enter` |

Before sending, **read the target pane first** (`herdr pane read`). If the peer's input box holds unsubmitted user text, do not inject; wait or ask the user to relay.

**Step 4 — receiver handling**

1. Read the new file under `inbox/<self>/` and **acknowledge immediately** to the sender: `{file} received` plus a one-line conclusion or next step (the ack travels as a herdr message, not another file).
2. **Delete the file once read** (the inbox only holds unread messages).
3. To reply with a body, write a file the same way in reverse and ring the doorbell; never stuff the body into the ack.

**Delivery proof**: the **peer's ack** is the only proof. `agent prompt` returning `{"type":"agent_prompted"}` and `send-text + send-keys` returning exit 0 count as "delivered", not "received". With no ack, **ask**; do not re-send blindly.

**Not versioned**: the inbox is a runtime channel, not a deliverable; a served project's `.gitignore` must contain `inbox/*/`.

### 1.4 Required harness skills (mattpocock)

The team depends on mattpocock's skills (`tdd` / `code-review` / `to-spec` / `to-tickets` / `research` / `grilling` and friends).
**Check**: the skills are visible in the current harness's skill directory (the user-level shared location is usually `~/.agents/skills/mattpocock-skills`, for reference only, not a hard criterion).

If missing, proceed in order:

```bash
# preferred: install per harness (pi / opencode / codebuddy / amp / cursor / devin / windsurf; omit -a to choose interactively)
npx skills@latest add mattpocock/skills -a <agent>
# fallback (when the prompt-based install fails): clone the source, copy the skill folders under skills/ into ~/.agents/skills/, then symlink them into the harness skill directory
git clone https://github.com/mattpocock/skills.git
```

Known gaps (checked 2026-10): upstream `mattpocock/skills` has **no `to-prd`**, and `implement-spec` is still unpublished under `in-progress/`. The director writes the PRD by hand from the template in §4; if upstream ships `to-prd` later, prefer it.

## 2. File naming (authoritative)

Sequence numbers are independent per output category and accumulate within the category (from 001): `{prd-seq}` (PRD), `{research-seq}` (research report), `{user-arch-seq}` (user architecture), `{user-plan-seq}` (user plan), `{spec-seq}` (shared by SPEC and ticket); inbox messages use a separate `{seq}` message number. `{slug}` is a short semantic name (lowercase English with hyphens, at most 5 words); `{YYMMDD-HHMM}` is date and time; `v{N}` is the version of the same file updated in place.

| Output | Directory | File name |
|---|---|---|
| Research report | `docs/research/` | `{research-seq}-research-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Product requirements (PRD) | `docs/pd/prd/` | `{prd-seq}-prd-{slug}-{YYMMDD}-v{N}.md` |
| Specification (SPEC) | `docs/pd/spec/` | `{spec-seq}-spec-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Development ticket | `docs/dev/tickets/` | `{spec-seq}-ticket-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| User architecture | `docs/user/user-arch/` | `{user-arch-seq}-arch-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| User plan | `docs/user/user-plan/` | `{user-plan-seq}-plan-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Inbox message | `inbox/<recipient>/` | `{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (no version, deleted once read) |

Rules:

1. **SPEC and ticket must share `spec-seq`**: one requirement's SPEC and its tickets use the same `spec-seq` prefix.
2. **Version semantics**: small in-version updates **edit the same file in place**; substantive revisions **start a new versioned file** (new timestamp, `v{N+1}`) and the old file is marked at the top with "superseded by v N+1".
3. The PRD uses the date only (`YYMMDD`) as required by the requesting side, with no time; every other output carries time.
4. **Independent numbering**: `{prd-seq}` / `{research-seq}` / `{user-arch-seq}` / `{user-plan-seq}` / `{spec-seq}` are independent and accumulate within their category; only SPEC and ticket share one `spec-seq`.
5. **Team lead numbering**: `{n}` in `dev-tl{n}` / `ana-tl{n}` matches the tab label and the inbox folder (`inbox/dev-tl{n}`, `inbox/ana-tl{n}`) in all three places, increases from 1, and is never reused after close.
6. Historical typos stay as history: the `ver{seq}` and `YYMMDD-v{seq}` forms in old requests are **void**; this table is authoritative, and existing files are not renamed.

## 3. Directory ownership

**Single allowed location (with owner and alignment requirement)**:

| Directory | Owner | Output | Alignment |
|---|---|---|---|
| `docs/pd/prd/` | director | Product requirements (PRD) | `{prd-seq}` independent numbering |
| `docs/pd/spec/` | director | Specification (SPEC, with acceptance criteria) | shares `spec-seq` with tickets |
| `docs/dev/tickets/` | dev-m (dev-e evidence is reported via the team lead and filed by dev-m) | Development tickets | shares `spec-seq` with the SPEC |
| `docs/research/` | ana-m | Market research and competitor reverse-engineering reports | none |
| `docs/user/user-arch/` | director | User architecture documents | none |
| `docs/user/user-plan/` | director | User plan documents | none |
| `docs/team.md` | director | Team contract (this file) | none |
| `docs/handoff/` | director / dev-m | Handoff notes (`{director,dev-m}-{slug}-{YYMMDD-HHMM}-v{N}.md`, **only when the user asks**) | none |
| `inbox/<recipient>/` | sender writes, receiver deletes after reading | Inter-role messages (runtime channel, **not versioned**, **at the project root, not under `docs/`**) | direction and `{seq}` per §1.3 |

1. These paths are the **only allowed locations**. Do not write to `docs/pd/` (except `prd/`, `spec/`), `docs/dev/` (except `tickets/`), `docs/user/` (except `user-arch/`, `user-plan/`), `docs/test/` or anywhere else; the inbox lives only under the project-root `inbox/` and never under `docs/`; do not create new document directories.
2. Department output directories **never cross**: read-only references are fine, moving or renaming is not.
3. **Team leads do not write `docs/`**: reports and evidence from `dev-tl{n}` / `ana-tl{n}` go to `inbox/<manager>/` only (the manager folds them into the ticket or report); everything under `docs/` is written by a manager.
4. The old layout (`docs/pd/` except `prd/` and `spec/`, `docs/dev/` except `tickets/`, `docs/test/`) is history only and **accepts no new output**; historical files are neither renamed nor moved. **Current ruling (2026-10-21, second revision)**: (1) the PRD lives in `docs/pd/prd/`; (2) the SPEC moved from `docs/spec/` to `docs/pd/spec/`; (3) tickets moved from `docs/tickets/` to `docs/dev/tickets/`; (4) `docs/user/user-arch/` (user architecture) and `docs/user/user-plan/` (user plan) were added, both written by the director; (5) `docs/dev/arch/` is **void**, no separate architecture directory; (6) the inbox moved from `docs/<role>/inbox/` to the project-root `inbox/<role>/`.
5. **The director initializes directories**: on taking over a project the director checks and fills gaps (see §3.1); ana-m / dev-m never create output directories.
6. Checker scope: the script in §7 only verifies that the six output directories and the root `inbox/` exist, that the five skills each point at their own directory, that this contract registers every path, and that a negative sample is rejected. It **does not validate individual file paths**; the table and reviews enforce those.

### 3.1 Initialization (director, idempotent)

The director's **first action** on a project is to check directories and create what is missing. Safe to repeat; existing directories are left alone:

```bash
cd <project root>
mkdir -p docs/{pd/{prd,spec},dev/tickets,research,user/{user-arch,user-plan}} inbox/{director,dev-m,ana-m}
grep -qxF 'inbox/*/' .gitignore 2>/dev/null || echo 'inbox/*/' >> .gitignore   # inbox is not versioned
bash director/scripts/check-pda-doc-paths.sh .
```

- **Done criterion**: the checker prints `ALL_PASS`. A missing directory prints `FAIL 目录缺失`; the director creates it and reruns.
- **Directories only, no artifacts**: no placeholder files, so an empty directory is never mistaken for a delivered artifact.
- **ana-m / dev-m never create output directories**: if a target directory is missing, report to the director (inbox folders are a runtime channel, `mkdir -p` is fine; `inbox/dev-tl{n}` and `inbox/ana-tl{n}` are created by the sender).
- The contract file `docs/team.md` and skill installation are outside this step (see `README.md`).

## 4. Workflow

1. **ana-m researches**: ana-m spawns `ana-tl{n}` as needed; the team lead dispatches `ana-e` to gather evidence; ana-m verifies and consolidates the research report, which lands in `docs/research/` **after director review**.
2. **director writes PRD and SPEC**: based on the research report and user conversations, the director produces the PRD and SPEC (with acceptance criteria), landing in `docs/pd/prd/` and `docs/pd/spec/` **after dev-m review**.
3. **dev-m splits tickets**: dev-m uses `/to-tickets` to cut the SPEC into matching development tickets under `docs/dev/tickets/`; dev-m consolidates, reviews and integrates the department's results.
4. **dev-m spawns team leads and dispatches tickets**: dev-m creates `dev-tl{n}` per batch and hands over the ticket (path, base sha, Files boundary, acceptance criteria, `timeoutMs`, report format); the team lead creates the worktree, dispatches `dev-e`, runs the implementation-level check and reports back to dev-m.
5. **dev-m integrates**: check the diff and the check readings → build and test → merge (resolve conflicts hunk by hunk by intent) → send failures back to the **same team lead** → update each ticket's status.
6. **Hand over to director review**: dev-m submits the code to the director **department**; one ticket maps to one SPEC. Chain: the director verifies against the SPEC acceptance criteria in person → the director gives a verdict → **the director notifies dev-m** → only then does dev-m `git push`.
7. **Parallelism**: for independent work, every role parallelizes **only across its own direct reports** (director across dev-m/ana-m; dev-m across multiple `dev-tl{n}`; ana-m across multiple `ana-tl{n}`; a team lead across multiple engineers). Priority: dynamic workflow > multiple parallel sub-agents. **Never serialize to save effort, and never dispatch across levels.**

### 4.1 PRD template (director)

`Problem Statement` / `Target users and scenarios` / `Solution overview` / `User stories (verifiable)` / `Acceptance criteria` / `Out of scope` / `Open questions`.

### 4.2 SPEC template (director)

`Problem Statement` / `Solution` / `User Stories` / `Acceptance criteria (each testable)` / `Implementation decisions` / `Test seams` / `Out of Scope` / `Change log`.
The SPEC must be self-contained: every User Story converts into a ticket and into test cases.

## 5. Discipline

### 5.1 Git

1. **Never `git add -A` / `git add .`**. Always list explicit paths (prefer `git commit -m "..." -- <path>` to bypass the index), and do nothing else between `add` and `commit` (so a concurrent writer cannot slip into the index).
2. Engineers (`dev-e`) run `git add` + `git commit` **inside their own worktree only**; **no `git push`**, **no merge into the trunk**. **Only dev-m may `git push`**, and only after the director has reviewed and notified.
3. Run `/code-review` before committing; after committing, verify the index with `git diff --cached --name-only`.

### 5.2 Parallel sub-agents

1. Do a **dependency analysis** before dispatching: only independent tasks run in parallel; tasks sharing files, sharing a build target or needing ordered acceptance must be serial.
2. Every dispatch prompt states: inputs (artifact paths), boundary, expected output, reporting requirements, `timeoutMs` (no shorter than 45 min for long chains).
3. Sub-agents are always dispatched in the background/async: **end the turn immediately after dispatching** and resume on the completion notification; never poll.
4. Each development engineer gets **one git worktree** and edits and commits only there; the main worktree is read-only.
5. Sub-agent results are written into authoritative documents or used downstream only after **the level that spawned them** verifies the evidence; a manager never accepts an engineer's raw report.

### 5.3 Review gates

| Gate | Submitted by | Reviewed by | Pass condition |
|---|---|---|---|
| Research report | ana-m | director | The director accepts the conclusions and sources; lands in `docs/research/` |
| PRD and SPEC | director | dev-m | dev-m accepts feasibility and slicing granularity; lands in `docs/pd/prd/` and `docs/pd/spec/` |
| Implementation check | dev-tl | dev-m | Every ticket criterion has a reading, red gates are classified, Files boundary respected |
| User architecture / user plan | director | User | Structure matches the real code, no future state mixed in; lands in `docs/user/user-arch/` and `docs/user/user-plan/` |
| Ticket code | dev-m | director | Every SPEC acceptance criterion passes; push only after the director notifies dev-m |
| Cross-department disagreement | dev-m / ana-m | director | The director arbitrates and replies with a ruling |

## 6. Writing style (all roles)

The reader is **someone who knows a little software engineering but did not work on this project** (the user included): plain language, conclusion before evidence, emphasise what matters, translate jargon into everyday words.

## 7. Checker

```bash
bash director/scripts/check-pda-doc-paths.sh
```

Four checks: the six output directories exist (`docs/pd/prd`, `docs/pd/spec`, `docs/dev/tickets`, `docs/research`, `docs/user/user-arch`, `docs/user/user-plan`) plus the root `inbox/`; the five skills (`director` / `dev-m` / `ana-m` / `dev-tl` / `ana-tl`) each point at their own directory; this contract registers every path; a negative sample is rejected. **Rerun after any path change.**

## 8. Change log

- **2026-10-22 (user ruling, org change)**: the project is named **dmt** and the organization is fixed at **four levels** `director → department manager → team lead → engineer`: (1) the top role is `director` (director, also product manager) with only `dev-m` and `ana-m` reporting to it; (2) development manager `dev-m` owns n development team leads `dev-tl{n}` (same label, spawned on demand with `herdr tab create --label`), each owning development engineers `dev-e`; (3) analysis manager `ana-m` owns n analysis team leads `ana-tl{n}`, each owning analysis engineers `ana-e`; (4) every role talks only to its direct superior and direct reports, and cross-department matters go through the director.
- **2026-10-21 (user ruling)**: (1) the PRD category **returns**, moving from `docs/prd/` to `docs/pd/prd/` (`docs/prd/` is void); (2) `docs/dev/arch/` is added as the **software design architecture** location, written by dev-m and reviewed by the director, named `{seq}-arch-{slug}-{YYMMDD-HHMM}--v{N}.md`.
- **2026-10-21 (user ruling, second)**: directory restructure: (1) the inbox moves to the project root `inbox/<director|dev-m|ana-m>/` and leaves `docs/` (`.gitignore` uses `inbox/*/`); (2) the SPEC moves from `docs/spec/` to `docs/pd/spec/`; (3) tickets move from `docs/tickets/` to `docs/dev/tickets/`; (4) `docs/user/user-arch/` and `docs/user/user-plan/` are added (both written by the director), and `docs/dev/arch/` is void.
- **2026-10-21 (user ruling, third)**: sequence numbers split by output category: PRD `{prd-seq}`, research report `{research-seq}`, user architecture `{user-arch-seq}`, user plan `{user-plan-seq}`, each independent and accumulating within its category; SPEC and ticket still share `{spec-seq}`; inbox messages keep the `{seq}` message number.
- **2026-10-21 (user ruling, fourth)**: directories are **checked and filled by the director at initialization** (§3.1 added, idempotent command + `ALL_PASS` criterion); ana-m / dev-m never create output directories and report gaps to the director.
