### 1.1 Organization and members

**Hierarchy**: `director` → `devm` / `anam` → `dev-e` / `ana-e`; `pde{n}` reports directly to the director. `reviewer{n}` runs on two tracks: the main track belongs to devm, the side track to director. The product department is folded into the director; there is no product-manager pane and no team-lead layer.

```
director            Director and Head of Product (label director, left side of the screen)
├── pde{n}             Product engineer (sub-agent, occupies no tab and no pane, dispatched by director itself; skill dmt-pde)
├── reviewer{n}        Review engineer · side track (sub-agent, occupies no pane, dispatched by director for spot checks / high-risk re-verification; skill dmt-reviewer)
├── devm               Development manager (label devm, pane on the right inside director's tab)
│   ├── dev-e          Development engineer (sub-agent, occupies no pane, dispatched directly by devm; skill dmt-de)
│   ├── reviewer{n}    Review engineer · main track (sub-agent, occupies no pane, dispatched by devm per ticket count for code review; skill dmt-reviewer)
│   └── dev-e ...
└── anam               Analysis manager (label anam, its own tab)
    ├── ana-e          Analysis engineer (sub-agent, occupies no pane, dispatched directly by anam; skill dmt-ae)
    └── ana-e ...
```

| Role | Skill name | Runtime id (pane label) | Direct superior | Direct reports | Responsibilities |
|---|---|---|---|---|---|
| Director and Head of Product | `dmt-director` | `director` | User | `devm`, `anam` (+ the `pde{n}`, `reviewer{n}` side-track sub-agents it dispatches itself) | Sole entry point for the user; takes requirements and the acceptance criteria, **summons `pde{n}` to draft the PRD / SPEC / tickets** (one unit per pde, fill every slot in parallel for independent units; the director sets the criteria and signs off at acceptance), writes the human documents and issues document gate verdicts, dispatches, arbitrates cross-department matters, creates and maintains the manager-layer panes/tabs; **merge / push belong to devm**; **hardware device writes may be performed by `devm` or `director`**; **the main track of code acceptance is dispatched by devm to `reviewer{n}`**; **the director dispatches the `reviewer{n}` side track for spot checks / high-risk re-verification** (spot-check verdicts go to `docs/handoff/` or back in the report); does not replace devm's code review |
| Development manager | `dmt-dm` | `devm` | `director` | `dev-e` / `reviewer{n}` (dispatches directly, fill every slot in parallel for tickets without dependencies) | Takes tickets (drafted by `pde{n}`, finalized by the director), schedules and assigns work, creates the worktree and dispatches `dev-e` to implement, collects the diff and runs the implementation-level first check, **code gate**: the person accountable for reviewing ticket code; **dispatches `reviewer{n}` per ticket for independent acceptance** (instances independent of `dev-e`, evidence is authoritative), integrates the development department's deliverables; **repository and device management**: merge / push belong to devm (**merge / push as soon as this department's `reviewer{n}` acceptance passes**); **hardware device writes may be performed by `devm` or `director`** (install / flash / overwrite device files / force-kill processes and the like, not limited to Android); **does not split tickets** |
| Analysis manager | `dmt-am` | `anam` | `director` | `ana-e` (dispatches directly, fill every slot in parallel for independent units) | Takes research requests; splits sub-questions, dispatches `ana-e` to gather evidence in parallel; verifies the primary sources and closes out the research report |

**Three-layer naming (never mix them up)**: ① **skill name** `dmt-dm` — used by the skill registry, the install directory and the `/dmt-dm` command; ② **runtime id** `devm` — used by the pane label, inbox directory, direction code and instance number; ③ **display name** Development manager — used in prose, reports and logs. Example: the command is written `/dmt-dm`, the path is written `inbox/devm/`, and the prose reads "Development manager reports: …".

| Skill name | Runtime id | Display name | Instance name |
|---|---|---|---|
| `dmt-director` | `director` | Director | — |
| `dmt-pde` | `pde{n}` | Product engineer | Product engineer 1, Product engineer 2 … |
| `dmt-reviewer` | `reviewer{n}` | Review engineer | Reviewer 1, Reviewer 2 … |
| `dmt-dm` | `devm` | Development manager | — |
| `dmt-am` | `anam` | Analysis manager | — |
| `dmt-de` | `dev-e` | Development engineer | By index, e.g. "Engineer 3" |
| `dmt-ae` | `ana-e` | Analysis engineer | By index, e.g. "Analysis engineer 3" |

**Single-line command (hard constraint: no role may skip a level or connect sideways):**

1. `director` commands **only** `devm` and `anam` directly, and may dispatch sub-agents such as `pde{n}` itself; it **must not** hand work to engineers or collect work from them, skipping a level.
2. `devm` spawns **only** `dev-e` sub-agents directly and `anam` **only** `ana-e` sub-agents — **managers always dispatch engineer sub-agents directly (fill every slot for tasks without dependencies, up to the harness concurrency cap)**, going through no intermediate layer (the team-lead layer has been removed).
3. `devm` and `anam` **do not connect directly**; cross-department matters are relayed by `director`.
4. Engineers `dev-e` / `ana-e` / `pde{n}` report **only** to the director or manager who spawned them, **do not install a standalone skill** (the skill is written into the dispatch prompt, see §1.4), **occupy no pane**, and **do not use cross-pane communication**.

**Managers self-start**: `devm` / `anam` may start work directly based on user requests and the ticket plan, notifying the director when they do. The director lets it through by default and only calls a stop when it considers it inappropriate; no one may stall on the grounds of not having received a reply.
