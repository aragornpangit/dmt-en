# dmt Team Contract

> This file is the **single team definition for dmt**: organization, members, communication, file naming, workflow, directory ownership and discipline. The five role skills `dmt-director` / `dmt-dm` / `dmt-am` / `dmt-dtl` / `dmt-atl` (runtime ids `director` / `devm` / `anam` / `devtl{n}` / `anatl{n}`) are implementation notes only; **this file wins on any conflict**.
> Team members run inside Herdr, a terminal multiplexer for AI agents. Sessions and panes change across restarts; this file does not record pane ids.

## 0. Repository layout

The repository root holds one folder per role. The team contract, the repo README and the path checker live with the director under `dmt-director/`, not loose at the root:

```
dmt/
├── dmt-director/                             # Director, also product manager (skill director)
│   ├── SKILL.md                          # role skill
│   ├── team.md                           # team contract (this file, single authority)
│   ├── README.md                         # repo notes and installation
│   └── scripts/check-dmt-doc-paths.sh    # output-path checker
├── dmt-dm/SKILL.md                        # Development manager
├── dmt-am/SKILL.md                        # Analysis manager
├── dmt-dtl/SKILL.md                       # Development team lead (devtl{n})
└── dmt-atl/SKILL.md                       # Analysis team lead (anatl{n})
```

## 1. Team definition

### 1.1 Organization and members

**Four levels**: `director` (director) → department manager (`devm` / `anam`) → team lead (`devtl{n}` / `anatl{n}`) → engineer (`dev-e` / `ana-e`). Five role skills, strictly four levels.

**The team-lead level is on demand.** When a manager needs to spread work in parallel it opens a team-lead pane inside **its own tab** (`herdr pane split`, pane label `devtl{n}`); the lead then spawns the engineer sub-agents. The lead pane is closed as soon as its batch is done.

```
director            Director (team lead + product manager, label director)
├── devm               Development manager (label devm)
│   ├── devtl1         Development team lead (pane label devtl1, inside devm's tab)
│   │   ├── dev-e       Development engineer (sub-agent, no pane)
│   │   └── dev-e ...
│   ├── devtl2 ...
│   └── devtl{n}
└── anam               Analysis manager (label anam)
    ├── anatl1         Analysis team lead (pane label anatl1, inside anam's tab)
    │   ├── ana-e       Analysis engineer (sub-agent, no pane)
    │   └── ana-e ...
    └── anatl{n}
```

| Role | Full name | Skill name | Runtime id (pane label) | Reports to | Direct reports | Responsibility |
|---|---|---|---|---|---|---|
| Director (team lead + product manager) | TeamLeader + ProductManager | `dmt-director` | `director` | Human | `devm`, `anam` | Single user entry point; take requirements, set acceptance criteria, write PRD and SPEC personally, review research reports and ticket code, arbitrate across departments |
| Development manager | DevelopManager | `dmt-dm` | `devm` | `director` | `devtl{n}` (pane, on demand) | Split the SPEC into tickets; open lead panes on demand; integrate and accept; push only after director review |
| Analysis manager | AnalystManager | `dmt-am` | `anam` | `director` | `anatl{n}` (pane, on demand) | Take research requests; open lead panes on demand; verify sources, consolidate the research report |
| Development team lead | DevelopLeader | `dmt-dtl` | `devtl{n}` | `devm` | `dev-e` (sub-agent) | Spawned on demand by the manager; create the worktree, dispatch development engineers, review the diff and run the implementation-level check, report to devm |
| Analysis team lead | AnalystLeader | `dmt-atl` | `anatl{n}` | `anam` | `ana-e` (sub-agent) | Spawned on demand by the manager; split sub-questions, dispatch analysis engineers in parallel, verify primary sources, report to anam |

**Three naming layers (never mixed)**: (1) **skill name** `dmt-dm` — used by the skill registry, the install directory and the `/dmt-dm` command; (2) **runtime id** `devm` — used by pane labels, inbox folders, direction codes and instance numbers; (3) **display name** Development manager — used by prose, reports and logs. Example: the command is `/dmt-dtl`, the path is `inbox/devtl1/`, and the prose says "lead 1 reported …".

**Single-line command (hard rule; no role may skip a level or connect sideways):**

1. `director` commands **only** `devm` and `anam`; **must not** task or receive from `devtl{n}` / `anatl{n}` / engineers directly.
2. `devm` **only** commands `devtl{n}`; it **must not** task `dev-e` directly, nor receive reports from dev-e directly.
3. `anam` **only** commands `anatl{n}`; it **must not** task `ana-e` directly, nor receive reports from ana-e directly.
4. A team lead reports **only** to its own department manager. `devtl{n}` and `anatl{n}` never connect to each other, nor do devm and anam; cross-department matters go through `director`.
5. Engineers `dev-e` / `ana-e` report **only** to the team lead that spawned them; they carry **no standalone skill**, **no pane** and **no cross-pane communication** (discipline lives in the dispatch prompt).

### 1.2 Runtime and pane lifecycle

**Identity is the pane label — not a position, not a tab.** Every role occupies one **pane**, and the pane label equals the role or instance name (`director` / `devm` / `anam` / `devtl{n}` / `anatl{n}`), **unique within the workspace**.

- **A tab is only a visual grouping**: `director` / `devm` / `anam` each occupy one tab, and the tab label matches the owner's pane label. **A team lead creates no tab**: its pane lives inside **its department manager's tab** (`devtl{n}` in `devm`'s tab, `anatl{n}` in `anam`'s tab).
- **Peers are identified by pane label** (filter `label` from `herdr pane list`), **never by position inside a tab and never by remembered pane id**: pane ids drift across restarts, and pane order changes on `pane swap` / `pane move` (measured: after a swap the `pane list` order flips immediately). **Only the label is stable.**
- **Engineers remain sub-agents**: `dev-e` / `ana-e` occupy no pane, carry no skill and do no cross-pane communication.
- **Startup order**: the user prepares the `director` tab and starts its harness; **the director creates the `devm` and `anam` tabs and labels each root pane with the same name**, then asks the user to start the harness in each of those tabs.
- **Team leads are spawned on demand and closed on completion**: the manager opens a lead pane **inside its own tab** with `pane split` and labels it. `{n}` increases monotonically from 1; **a closed number is never reused**; closing rules are at the end of this section.
- **Capacity**: every extra lead pane halves the manager's own width (on a 118-column terminal, two panes give 59 columns each and three give about 39). **Keep at most two leads per tab** as a rule of thumb; beyond that, split the batch or temporarily `herdr pane zoom` one pane.

```bash
# resolve by pane label (match on label text, never copy a historical pane id)
HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
  | jq -r --arg l "<role name>" '.result.panes[] | select(.label==$l) | .pane_id'
```

If the target label is absent: **stop and ask the user**. Do not guess a pane id and do not retry against a session that does not exist.
**Migration fallback** (only while labels are missing): if a tab with the same label exists and holds exactly one pane, use that pane; otherwise still stop and ask the user.

**Identity self-heal** (the first thing every role does after start): read `herdr pane get "$HERDR_PANE_ID"`; if the label does not match the role name (including empty), immediately run `herdr pane rename "$HERDR_PANE_ID" <role name>`. A team lead **must not** identify itself through `herdr tab list` — that tab label belongs to its manager.

Create a pane:

```bash
# (1) manager tab (created by the director): label the root pane with the same name right away
tab_json=$(HERDR_ENV=1 herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label devm)
pane=$(echo "$tab_json" | jq -r '.result.root_pane.pane_id')
HERDR_ENV=1 herdr pane rename "$pane" devm

# (2) team-lead pane (created by the manager): append it to the right of the manager's own tab,
#     no focus steal, no new tab
pane=$(HERDR_ENV=1 herdr pane split "$HERDR_PANE_ID" --direction right --cwd "$PWD" --no-focus \
  | jq -r '.result.pane.pane_id')
HERDR_ENV=1 herdr pane rename "$pane" devtl1
```

**Bringing a lead pane into role** (started by the creator; never handed to the user):

```bash
HERDR_ENV=1 herdr pane send-text "$pane" 'codebuddy --permission-mode auto'
HERDR_ENV=1 herdr pane send-keys "$pane" enter
# wait for readiness: --source visible avoids matching stale scrollback
HERDR_ENV=1 herdr pane wait-output "$pane" --source visible --match 'auto mode on' --timeout 60000
```

Once ready, the creator delivers the first task (role name, skill name, manager's label, task file path) and verifies with `pane read` that **the input box is empty** — that is what counts as delivered (`enter` is often swallowed; just send it again).

**Switch the permission mode before delivering the first task (sessions started by the user only).** The order cannot be reversed:

1. after the harness starts and **before the first message**, press `shift+Tab` to switch to `auto mode`;
2. read the bottom of the pane once and **confirm `auto mode on` is visible**;
3. only then deliver the first task.

**Why it must happen before the first message**: once the conversation starts the permission mode is locked, and switching later fails with `Mode cannot be changed after the conversation starts`. The only remedy is `/clear` and a restart, which throws away the engineer sub-agents already running and the context already built.

> Do not confuse two different things: `/agent-mode` (PTC vs normal) cannot change after a session starts and is unrelated to this section; this section is about the **permission mode** cycled by `shift+Tab`. They are independent, and a PTC session can also run `auto mode`.

**Cost of skipping it**: the team lead stalls on pop-ups such as `High risk operation detected - requires confirmation every time`, which often guard nothing more than `cmake` / `ctest`.

> **A lead pane started by its creator skips this flow**: the launch command already carries `--permission-mode auto`, so there is no "locked once the conversation starts" window. **Do not** press `shift+Tab` there — pressing it cycles the mode away.

#### Closing a team-lead instance (close on completion)

Only team leads are **on-demand instances**; the `devm` / `anam` panes and tabs are **permanent** and are never closed with a batch.

- **Owner**: **the creator itself** — `devm` closes `devtl{n}`, `anam` closes `anatl{n}`. Herdr's safety rule is "never close a pane or tab you did not create", so the director and other roles **must not close on someone's behalf**.
- **Timing**: after **every task of that team lead's batch is closed out** and the creator **confirms there is no next batch to dispatch**. **Reusable within one batch** (several tickets or sub-questions of the same batch may go to the same lead; no need to create one per ticket), **never carried across batches** — the batch ends, the tab closes, and the next batch starts a new number.
- **Three preconditions, fixed order, none optional**: (1) the lead's report (with per-criterion readings / primary sources) is folded into the ticket or report; (2) every worktree under that lead is removed with `git worktree remove` and no workspace is left behind; (3) `inbox/<creator>/` holds no unread message from that lead.
- **Command and success criterion**:

```bash
# 1) resolve the current pane from the label (never copy a historical id)
tl=$(HERDR_ENV=1 herdr pane list --workspace "$HERDR_WORKSPACE_ID" \
  | jq -r '.result.panes[] | select(.label=="devtl1") | .pane_id')
# 2) close; success criterion = the label is gone from pane list
HERDR_ENV=1 herdr pane close "$tl"
```

- **`herdr tab close` is forbidden**: a lead pane shares its manager's tab, so closing the tab would kill the manager itself (and every other lead in the batch). Only panes may be closed.
- **Risk clause**: closing a pane terminates that agent's session; **context cannot be recovered and the action cannot be undone** ⇒ **never close before collecting**; closing must happen after the report is filed and the worktree is reclaimed.
- **Numbering**: a closed number is **never reused** (§2 rule 5); after closing, report to the user in one line (which instance, why).

### 1.3 Communication (inbox file + herdr doorbell)

**All bodies travel as files; herdr carries one doorbell line only.** Dispatch, reports, review verdicts, arbitration requests and defect returns all become a file in the receiver's inbox first, then herdr rings once with "you have a new message <file>". **Never paste long bodies, logs or diffs into the message.**

**Direct communication is allowed only along the reporting line** (everything else is relayed by the manager):

| From | To | Direction code |
|---|---|---|
| `director` | `devm` / `anam` | `director2devm` / `director2anam` |
| `devm` / `anam` | `director` | `devm2director` / `anam2director` |
| `devm` | `devtl{n}` | `devm2devtl{n}` |
| `devtl{n}` | `devm` | `devtl{n}2devm` |
| `anam` | `anatl{n}` | `anam2anatl{n}` |
| `anatl{n}` | `anam` | `anatl{n}2anam` |

**Step 1 — locate the peer** (re-resolve every time; never reuse a pane id): `herdr pane list` gives the **current** pane id for a **pane label** (the label equals the role name and is unique in the workspace). Label missing ⇒ **stop and ask the user**; do not guess a pane id and do not fall back to a position inside a tab.

**Step 2 — write the inbox file**

- Path: `inbox/<recipient>/{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` at the **project root** (`<recipient>` ∈ `director` / `devm` / `anam` / `devtl{n}` / `anatl{n}`; **not under `docs/`**; `mkdir -p` if missing).
- `{seq}`: per-sender running number from 001, one number per message (unrelated to the SPEC `spec-seq`).
- `{direction}`: from the table above; cross-department traffic is relayed by the director, so `devm2anam` / `devtl2anatl` never appear.
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

1. On the doorbell alert (new mail in the inbox), read the new file under `inbox/<self>/` and **load it into your context window** for processing.
2. **Do not send a receipt**: after reading, process it; do **not** send `{file} received` or any acknowledgement message.
3. **Delete the file once read** (the inbox only holds unread messages).
4. To reply with a body, write a file the same way in reverse and ring the doorbell; never stuff the body into the doorbell line.

**Delivery proof**: the sender treats a successful doorbell as "delivered" (`agent prompt` returns `{"type":"agent_prompted"}`, or `send-text + send-keys` returns exit 0). **The receiver sends no receipt**, so delivery is no longer proven by an ack. If the sender is unsure whether the message was read, **ask the user verbally**; do not re-send blindly.

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

Sequence numbers are independent per output category and accumulate within the category (from 001): `{prd-seq}` (PRD), `{research-seq}` (research report), `{human-arch-seq}` (human architecture), `{human-plan-seq}` (human plan), `{spec-seq}` (shared by SPEC and ticket); inbox messages use a separate `{seq}` message number. `{slug}` is a short semantic name (lowercase English with hyphens, at most 5 words); `{YYMMDD-HHMM}` is date and time; `v{N}` is the version of the same file updated in place.

| Output | Directory | File name |
|---|---|---|
| Research report | `docs/analyst/` | `{research-seq}-research-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Product requirements (PRD) | `docs/pd/prd/` | `{prd-seq}-prd-{slug}-{YYMMDD}-v{N}.md` |
| Specification (SPEC) | `docs/pd/spec/` | `{spec-seq}-spec-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Development ticket | `docs/dev/tickets/` | `{spec-seq}-ticket-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Human architecture | `docs/human/human-arch/` | `{human-arch-seq}-arch-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Human plan | `docs/human/human-plan/` | `{human-plan-seq}-plan-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Inbox message | `inbox/<recipient>/` | `{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (no version, deleted once read) |

Rules:

1. **SPEC and ticket must share `spec-seq`**: one requirement's SPEC and its tickets use the same `spec-seq` prefix.
2. **Version semantics**: small in-version updates **edit the same file in place**; substantive revisions **start a new versioned file** (new timestamp, `v{N+1}`) and the old file is marked at the top with "superseded by v N+1".
3. The PRD uses the date only (`YYMMDD`) as required by the requesting side, with no time; every other output carries time.
4. **Independent numbering**: `{prd-seq}` / `{research-seq}` / `{human-arch-seq}` / `{human-plan-seq}` / `{spec-seq}` are independent and accumulate within their category; only SPEC and ticket share one `spec-seq`.
5. **Team lead numbering**: `{n}` in `devtl{n}` / `anatl{n}` matches the **pane label** and the inbox folder (`inbox/devtl{n}`, `inbox/anatl{n}`) in all three places, increases from 1, and is never reused after close.
6. Historical typos stay as history: the `ver{seq}` and `YYMMDD-v{seq}` forms in old requests are **void**; this table is authoritative, and existing files are not renamed.

## 3. Directory ownership

**Single allowed location (with owner and alignment requirement)**:

| Directory | Owner | Output | Alignment |
|---|---|---|---|
| `docs/pd/prd/` | director | Product requirements (PRD) | `{prd-seq}` independent numbering |
| `docs/pd/spec/` | director | Specification (SPEC, with acceptance criteria) | shares `spec-seq` with tickets |
| `docs/dev/tickets/` | devm (dev-e evidence is reported via the team lead and filed by devm) | Development tickets | shares `spec-seq` with the SPEC |
| `docs/analyst/` | anam | Market research and competitor reverse-engineering reports | none |
| `docs/human/human-arch/` | director | Human architecture documents | none |
| `docs/human/human-plan/` | director | Human plan documents | none |
| `docs/team.md` | director | Team contract (this file) | none |
| `docs/handoff/` | director / devm | Handoff notes (`{director,devm}-{slug}-{YYMMDD-HHMM}-v{N}.md`, **only when the user asks**) | none |
| `inbox/<recipient>/` | sender writes, receiver deletes after reading | Inter-role messages (runtime channel, **not versioned**, **at the project root, not under `docs/`**) | direction and `{seq}` per §1.3 |

1. These paths are the **only allowed locations**. Do not write to `docs/pd/` (except `prd/`, `spec/`), `docs/dev/` (except `tickets/`), `docs/human/` (except `human-arch/`, `human-plan/`), `docs/test/` or anywhere else; the inbox lives only under the project-root `inbox/` and never under `docs/`; do not create new document directories.
2. Department output directories **never cross**: read-only references are fine, moving or renaming is not.
3. **Team leads do not write `docs/`**: reports and evidence from `devtl{n}` / `anatl{n}` go to `inbox/<manager>/` only (the manager folds them into the ticket or report); everything under `docs/` is written by a manager.
4. The old layout (`docs/pd/` except `prd/` and `spec/`, `docs/dev/` except `tickets/`, `docs/test/`) is history only and **accepts no new output**; historical files are neither renamed nor moved. **Current ruling (2026-10-21, second revision)**: (1) the PRD lives in `docs/pd/prd/`; (2) the SPEC moved from `docs/spec/` to `docs/pd/spec/`; (3) tickets moved from `docs/tickets/` to `docs/dev/tickets/`; (4) `docs/human/human-arch/` (human architecture) and `docs/human/human-plan/` (human plan) were added, both written by the director; (5) `docs/dev/arch/` is **void**, no separate architecture directory; (6) the inbox moved from `docs/<role>/inbox/` to the project-root `inbox/<role>/`.
5. **The director initializes directories**: on taking over a project the director checks and fills gaps (see §3.1); anam / devm never create output directories.
6. Checker scope: the script in §7 only verifies that the six output directories and the root `inbox/` exist, that the five skills each point at their own directory, that this contract registers every path, and that a negative sample is rejected. It **does not validate individual file paths**; the table and reviews enforce those.

### 3.1 Initialization (director, idempotent)

The director's **first action** on a project is to check directories and create what is missing. Safe to repeat; existing directories are left alone:

```bash
cd <project root>
mkdir -p docs/{pd/{prd,spec},dev/tickets,analyst,human/{human-arch,human-plan}} inbox/{director,devm,anam}
grep -qxF 'inbox/*/' .gitignore 2>/dev/null || echo 'inbox/*/' >> .gitignore   # inbox is not versioned
bash dmt-director/scripts/check-dmt-doc-paths.sh .
```

- **Done criterion**: the checker prints `ALL_PASS`. A missing directory prints `FAIL 目录缺失` (directory missing); the director creates it and reruns.
- **Directories only, no artifacts**: no placeholder files, so an empty directory is never mistaken for a delivered artifact.
- **anam / devm never create output directories**: if a target directory is missing, report to the director (inbox folders are a runtime channel, `mkdir -p` is fine; `inbox/devtl{n}` and `inbox/anatl{n}` are created by the sender).
- The contract file `docs/team.md` and skill installation are outside this step (see `README.md`).

## 4. Workflow

1. **anam researches**: anam opens `anatl{n}` lead panes on demand and the lead dispatches `ana-e`; anam verifies and consolidates the research report, which lands in `docs/analyst/` **after director review**; **once the batch is fully closed out with no next batch to dispatch, anam closes that batch's `anatl{n}` (§1.2)**.
2. **director writes PRD and SPEC**: based on the research report and user conversations, the director produces the PRD and SPEC (with acceptance criteria), landing in `docs/pd/prd/` and `docs/pd/spec/` **after devm review**.
3. **devm splits tickets**: devm uses `/to-tickets` to cut the SPEC into matching development tickets under `docs/dev/tickets/`; devm consolidates, reviews and integrates the department's results.
4. **devm opens a lead pane and dispatches**: devm creates `devtl{n}` in its own tab and hands over the ticket (path, base sha, Files boundary, acceptance criteria, `timeoutMs`, report format); the team lead creates the worktree, dispatches `dev-e`, runs the implementation-level check and reports back. **One ticket, one writer.**
5. **devm integrates**: check the diff and the check readings the lead reported → build and test → merge (resolve conflicts hunk by hunk by intent) → send failures back to the **same team lead** (which returns them to the same dev-e) → update each ticket's status; **once the batch is fully closed out with no next batch to dispatch, close that batch's `devtl{n}` (§1.2)**.
6. **Hand over to director review**: devm submits the code to the director **department**; one ticket maps to one SPEC. Chain: the director verifies against the SPEC acceptance criteria in person → the director gives a verdict → **the director notifies devm** → only then does devm `git push`.
7. **Parallelism**: for independent work, every role parallelizes **across its direct reports, as many as the work allows** (director across dmt-dm/anam; devm across multiple `devtl{n}`; anam across multiple `anatl{n}`; a team lead across multiple engineers). Priority: dynamic workflow > multiple parallel sub-agents. **Never serialize to save effort, and never dispatch across levels.**

### 4.1 PRD template (director)

`Problem Statement` / `Target users and scenarios` / `Solution overview` / `User stories (verifiable)` / `Acceptance criteria` / `Out of scope` / `Open questions`.

### 4.2 SPEC template (director)

`Problem Statement` / `Solution` / `User Stories` / `Acceptance criteria (each testable)` / `Implementation decisions` / `Test seams` / `Out of Scope` / `Change log`.
The SPEC must be self-contained: every User Story converts into a ticket and into test cases.

## 5. Discipline

### 5.1 Git

1. **Never `git add -A` / `git add .`**. Always list explicit paths (prefer `git commit -m "..." -- <path>` to bypass the index), and do nothing else between `add` and `commit` (so a concurrent writer cannot slip into the index).
2. Engineers (`dev-e`) run `git add` + `git commit` **inside their own worktree only**; **no `git push`**, **no merge into the trunk**. **Only devm may `git push`**, and only after the director has reviewed and notified.
3. Run `/code-review` before committing; after committing, verify the index with `git diff --cached --name-only`.
4. **One writer per worktree (the team lead included)**: from start to finish a worktree has **exactly one agent allowed to commit** — the one dispatched to that ticket. A lead that needs to commit tickets or documents **must not** do it inside the worktree an engineer is working in: use the main worktree or a separate one. **Concurrent commits raise no error; they simply sweep someone else's changes into your commit**, and only `git show --stat` reveals it afterwards — by then it is already history.
   - **Why**: on 2026-10-23 devtl1 committed four docs commits in parallel inside the same worktree dev-e13 was working in. Nothing was lost, but the lead itself noted that "a lucky outcome does not make the process right". **The rule existed only in the director's memory and was never written into this file** — an unwritten rule is not a rule.
   - **How to apply**: before committing, run `git status` and look for someone else's uncommitted changes; if any exist, switch to `git commit -- <your paths>` **without** `add` first; if the same worktree already holds another writer's changes, stop and ask devm instead of judging that "it is probably fine".

### 5.2 Parallel sub-agents

1. Do a **dependency analysis** before dispatching: only independent tasks run in parallel; tasks sharing files, sharing a build target or needing ordered acceptance must be serial.
2. **Testable criterion at team-lead level**: independent units (tickets / evidence units) **≥2 ⇒ dispatch concurrently**; the only exception is **stating the serial reason in the report** (reason limited to: dependency / shared files / shared build target / ordered acceptance). Priority: dynamic workflow `runs.all` > multiple parallel sub-agents.
   - **The same criterion applies at manager level**: **≥2 independent tickets or sub-questions must likewise run concurrently**, spread over multiple lead panes — "the manager is one person" is not a reason to serialize.
3. Every dispatch prompt states: inputs (artifact paths), boundary, expected output, reporting requirements, `timeoutMs` (no shorter than 45 min for long chains).
4. Sub-agents are always dispatched in the background/async: **end the turn immediately after dispatching** and resume on the completion notification; never poll.
5. Each development engineer gets **one git worktree** and edits and commits only there; the main worktree is read-only.
6. Sub-agent results are written into authoritative documents or used downstream only after **the team lead that spawned them** verifies the evidence; a manager never accepts an engineer's raw report — it goes through the lead.

### 5.3 Review gates

| Gate | Submitted by | Reviewed by | Pass condition |
|---|---|---|---|
| Research report | anam | director | The director accepts the conclusions and sources; lands in `docs/analyst/` |
| PRD and SPEC | director | devm | devm accepts feasibility and slicing granularity; lands in `docs/pd/prd/` and `docs/pd/spec/` |
| Implementation check | devtl | devm | Every ticket criterion has a reading, red gates are classified, Files boundary respected |
| Team-lead instance close | devm / anam (creator) | creator self-check | Report filed, worktree removed with `git worktree remove`, no unread message in the inbox; after closing, `herdr pane list` no longer shows the label |
| Human architecture / human plan | director | User | Structure matches the real code, no future state mixed in; lands in `docs/human/human-arch/` and `docs/human/human-plan/` |
| Ticket code | devm | director | Every SPEC acceptance criterion passes; push only after the director notifies devm |
| Cross-department disagreement | devm / anam | director | The director arbitrates and replies with a ruling |

## 6. Writing style (all roles)

The reader is **someone who knows a little software engineering but did not work on this project** (the user included): plain language, conclusion before evidence, emphasise what matters, translate jargon into everyday words.

## 7. Checker

```bash
bash dmt-director/scripts/check-dmt-doc-paths.sh
```

**Seven** checks: (1) the six output directories exist (`docs/pd/prd`, `docs/pd/spec`, `docs/dev/tickets`, `docs/analyst`, `docs/human/human-arch`, `docs/human/human-plan`) plus the root `inbox/`; (2) the five skills (`dmt-director` / `dmt-dm` / `dmt-am` / `dmt-dtl` / `dmt-atl`) each point at their own directory; (3) **the team-lead close action is registered** (this contract and the `dmt-dm` / `dmt-am` skills contain `herdr pane close`, and this contract contains "never close before collecting" and "Only panes may be closed"); (4) **identity resolution is registered** (this contract and all five skills contain `pane label`, and this contract forbids resolving by position inside a tab); (5) **the team-lead parallelism criterion is registered** (`dmt-dtl` / `dmt-atl` contain "must run in parallel", and this contract contains "≥2 ⇒ dispatch concurrently"); (6) this contract registers every path; (7) a negative sample is rejected (**only the §3 table is inspected**; historical notes in §8 do not count as registration). **Rerun after any change to paths, pane lifecycle or parallelism criteria.**

## 8. Change log

- **2026-10-24 (user ruling, tenth: identity moves to pane label + team-lead panes inside the manager tab)**: (1) **The 2026-10-23 ninth ruling ("self-run / delegated") is rolled back** — the manager level keeps a single path (open lead panes inside its own tab, the lead then spawns the engineer sub-agents); engineers are always the lead's sub-agents and a manager never tasks dev-e directly. §4.0 is deleted, and §1.1 rules 2/3/5, §4, §5.2, §5.3 and checker item 4b are rolled back with it. (2) **Identity moves from "tab label + first pane in the tab" to "pane label"**: the pane label equals the role or instance name and is unique in the workspace; **position inside a tab is no longer used** (measured: `pane swap` flips the `pane list` order immediately, so "the first pane" silently addresses the wrong agent). (3) **Team-lead panes open inside the manager's own tab**: `herdr pane split "$HERDR_PANE_ID" --direction right --no-focus` plus `pane rename`; no tab is created and the tab degrades to a visual grouping. (4) **The creator starts the lead pane**: `pane send-text 'codebuddy --permission-mode auto'` + `pane send-keys enter`, readiness via `wait-output --source visible --match 'auto mode on'`; therefore leads **skip** the `shift+Tab` permission-mode flow, which now applies only to sessions the user starts by hand. (5) **Closing uses `herdr pane close`**, and **`herdr tab close` is forbidden** — a lead shares its manager's tab, so closing the tab would kill the manager and every other lead in the batch. (6) **Identity self-heal**: every role checks the label of `$HERDR_PANE_ID` after start and renames it when it does not match; a lead must not identify itself through `tab list`. (7) Capacity note: keep at most two lead panes per tab, otherwise split the batch or use `pane zoom`. Synced changes: the five skills (`dmt-dm` / `dmt-am` / `dmt-dtl` / `dmt-atl` and `dmt-director`), `README.md` and the checker.
- **2026-10-23 (user ruling, ninth: two staffing paths at manager level — rolled back by the tenth, kept for history only)**:  managers (`devm` / `anam`) no longer have "create a lead" as their only option. (1) **§4.0 staffing mode** added: **self-run** (the manager spawns engineer sub-agents inside its own session, as many as the work allows) and **delegated** (`herdr tab create` a lead, which then spawns the engineers) are **equally legitimate** and may be mixed within a batch; criteria: ≤2 units with context at hand ⇒ self-run, ≥3 units or wide parallelism / independent check ⇒ delegated. (2) **Single-line command rewritten** (§1.1 rules 2 and 3): a manager's **cross-session** reports are still only team leads; engineers exist only as **sub-agents inside the manager's own session** (self-run) or as a lead's sub-agents (delegated), and **treating an engineer as a tab-level peer or talking across tabs stays forbidden**. (3) Engineers report to "the level that spawned them" (rule 5) — under self-run that is the manager. (4) **The parallelism criterion drops to manager level** (§5.2): self-run parallelizes multiple engineer sub-agents, and ≥2 independent units must likewise run concurrently, as many as the work allows. (5) **A self-run batch has no tab, no inbox message and no `herdr tab close`** (§1.2, §4.0); the check is never skipped by handing it to yourself (§5.3 row now reads "devtl (delegated) / devm itself (self-run)"). (6) Role names unified: development manager (devm), development team lead (devtl), analysis manager (anam), analysis team lead (anatl); skill ids unchanged. (7) The checker gains a seventh assertion: `devm` / `anam` contain "self-run" and this contract carries §4.0 "staffing mode".
- **2026-10-22 (user ruling, eighth: unified parallelism criterion at team-lead level)**: `devtl` previously said tickets "may" run in parallel while `anatl` said "must", so the two levels disagreed and the level with the real resource limits said nothing. (1) Both skills' step 3 now use one wording: **independent units must run in parallel, as many as the work allows** (concurrent dispatch in the same reply, dynamic workflow `runs.all` first, then multiple sub-agents; end the turn immediately, never poll); **only** dependency / shared files / shared build target / ordered acceptance justify serial work, **and the reason must be stated in the report**; concurrency is bounded by resources (development lead: **no concurrent builds inside one worktree**; analysis lead: no concurrency on the same input file / device / REA session). (2) §5.2 gains the **testable criterion**: independent units ≥2 ⇒ dispatch concurrently, exception only with a stated serial reason. (3) The checker gains static assertions.
- **2026-10-22 (user ruling, seventh: team-lead tab lifecycle completed — "close on completion")**: previously only the "spawn on demand" half existed. (1) **Owner** = the creator (`devm` closes `devtl{n}`, `anam` closes `anatl{n}`); nobody else may close on its behalf (matching herdr's "never close a tab you did not create"). (2) **Timing** = the batch is fully closed out and the creator confirms no next batch, **reusable within a batch, never carried across batches**. (3) **Three preconditions** (report filed, worktree removed, no unread inbox message) **in fixed order, none optional**. (4) **Command** `herdr tab close <tab_id>` with the id resolved from the label at that moment, **success criterion** = the label disappears from `tab list`. (5) **Never close before collecting** — closing kills the agent session, the context cannot be recovered and the action cannot be undone. (6) The `devm` / `anam` tabs stay **permanent** and are outside this ruling. (7) The checker gains assertions for the close action.
- **2026-10-22 (checker fix, not a user ruling)**: the §7 negative-sample assertion was self-contradictory — the script grepped the whole contract for the bad path while §8 must record that path, so the assertion was permanently red (the pre-change `HEAD` failed the same way). It now inspects **only the §3 table rows**, keeping the tooth (writing the bad path into the table still fails) while historical notes no longer trip it.
- **2026-10-22 (user ruling, org change)**: the project is named **dmt** and the organization is fixed at **four levels** `director → department manager → team lead → engineer`: (1) the top role is `director` (director, also product manager) with only `devm` and `anam` reporting to it; (2) development manager `devm` owns n development team leads `devtl{n}` (same label, spawned on demand with `herdr tab create --label`), each owning development engineers `dev-e`; (3) analysis manager `anam` owns n analysis team leads `anatl{n}`, each owning analysis engineers `ana-e`; (4) every role talks only to its direct superior and direct reports, and cross-department matters go through the director.
- **2026-10-21 (user ruling)**: (1) the PRD category **returns**, moving from `docs/prd/` to `docs/pd/prd/` (`docs/prd/` is void); (2) `docs/dev/arch/` is added as the **software design architecture** location, written by devm and reviewed by the director, named `{seq}-arch-{slug}-{YYMMDD-HHMM}--v{N}.md`.
- **2026-10-21 (user ruling, second)**: directory restructure: (1) the inbox moves to the project root `inbox/<director|devm|anam>/` and leaves `docs/` (`.gitignore` uses `inbox/*/`); (2) the SPEC moves from `docs/spec/` to `docs/pd/spec/`; (3) tickets move from `docs/tickets/` to `docs/dev/tickets/`; (4) `docs/human/human-arch/` and `docs/human/human-plan/` are added (both written by the director), and `docs/dev/arch/` is void.
- **2026-10-21 (user ruling, third)**: sequence numbers split by output category: PRD `{prd-seq}`, research report `{research-seq}`, human architecture `{human-arch-seq}`, human plan `{human-plan-seq}`, each independent and accumulating within its category; SPEC and ticket still share `{spec-seq}`; inbox messages keep the `{seq}` message number.
- **2026-10-21 (user ruling, fourth)**: directories are **checked and filled by the director at initialization** (§3.1 added, idempotent command + `ALL_PASS` criterion); anam / devm never create output directories and report gaps to the director.
- **2026-10-22 (user ruling, fifth)**: directory rename: (1) the research-report directory `docs/research/` becomes `docs/analyst/` (still owned by anam); (2) `docs/user/` becomes `docs/human/`, with `user-arch/`→`human-arch/` and `user-plan/`→`human-plan/` underneath (still owned by the director); (3) the checker script `check-pda-doc-paths.sh` is renamed `check-dmt-doc-paths.sh`, and inside it `PDA_SKILLS_DIR`→`DMT_SKILLS_DIR` and the negative sample `docs/not-a-pda-output-dir/`→`docs/not-a-dmt-output-dir/`.
- **2026-10-22 (user ruling, sixth)**: inbox protocol simplified: on the doorbell alert the receiver loads the file into its context window, **sends no receipt**, and deletes it once read; delivery is proven by a successful doorbell send, not by an ack; also clarified that one herdr tab holds exactly one pane (one agent) — **superseded by the tenth ruling**.
