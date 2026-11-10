# dmt Team Contract

> **Version 5.19.9 · 2026-11-10** — same number as the `version:` field in the seven `SKILL.md` files; a different number means the wrong install.
> **Scope**: every discipline in this contract (permissions / write ownership / gates / pane / inbox) **applies only to the "target project" managed by dmt** (the root initialized by `init-project.sh`); **it does not apply when maintaining the skill repositories themselves** (`dmt` / `dmt-en` and the like) — a maintainer may `commit` / `push` directly, with no director authorization and no devm pushing on their behalf.
> **Routing**: this file defines the constants; read task details from its sections, and route operating procedures through [`OPS.md`](OPS.md). This file prevails in any conflict.

## Task routing

| Topic | Location |
|---|---|
| §1.1 Organization and members (hierarchy / org chart / role table / three-layer naming / single-line command / self-start) | [`team/01-org.md`](team/01-org.md) |
| §1.2 Runtime environment and pane lifecycle (harness compatibility / permission-mode re-verification) | [`team/02-runtime.md`](team/02-runtime.md) |
| §1.3 Communication / §1.4 Mandatory skills / §1.5 File claims | [`team/03-comms.md`](team/03-comms.md) |
| §2 File naming conventions (authoritative) | [`team/04-naming.md`](team/04-naming.md) |
| §3 Directory responsibilities / §3.1 Initialization | [`team/05-dirs.md`](team/05-dirs.md) |
| §4 Workflow (PRD / SPEC / ticket templates) | [`team/06-workflow.md`](team/06-workflow.md) |
| §5 Discipline (Git / parallel sub-agents / review gates / reading discipline) | [`team/07-discipline.md`](team/07-discipline.md) (dispatch prompt templates and pi hosting: [`team/07b-dispatch.md`](team/07b-dispatch.md)) |
| §6 Expression | [`team/08-expression.md`](team/08-expression.md) |
| §7 Machine check | [`team/09-check.md`](team/09-check.md) |
| §10 Common actions for pane roles | [`team/10-pane-role.md`](team/10-pane-role.md) |
| Top-level operational routing | [`OPS.md`](OPS.md) |

## Roles and chain of command

Hierarchy: `director` (Director and Head of Product) → managers (`devm` / `anam`) → engineers (`dev-e` / `ana-e`; `pde{n}` reports directly to the director). `reviewer{n}` runs on **two tracks**: the main track belongs to `devm` (code review), the side track belongs to `director` (spot checks / high-risk re-verification only).

| Role | Skill | Runtime id | Reports to | Direct reports |
|---|---|---|---|---|
| Director and Head of Product | `dmt-director` | `director` | User | `devm`, `anam` (+ the `pde{n}` / `reviewer{n}` side-track sub-agents it dispatches itself) |
| Development manager | `dmt-dm` | `devm` | `director` | `dev-e`, `reviewer{n}` (main track) |
| Analysis manager | `dmt-am` | `anam` | `director` | `ana-e` |
| Product engineer | `dmt-pde` | `pde{n}` | `director` | — |
| Development engineer | `dmt-de` | `dev-e` | `devm` | — |
| Analysis engineer | `dmt-ae` | `ana-e` | `anam` | — |
| Review engineer | `dmt-reviewer` | `reviewer{n}` | main track `devm` / side track `director` | — |

**Command line**: director → devm / anam → engineers; pde reports directly to the director; reviewer belongs to devm on the main track and to director on the side track. Cross-department matters go through the director.

**Write operations**: merge / push belong to devm only; hardware device writes may be performed by devm or director, with a single writer per device.

**Parallelism**: fill every subagent slot for tasks without dependencies; shared files, build targets, devices or ordered acceptance must be serialized.

**Mandatory skills**: each role invokes them per [`team/03-comms.md`](team/03-comms.md) §1.4; if unavailable, install first; if still unavailable, mark `[SKILL_UNAVAILABLE]`.

**Machine check**:

```bash
bash dmt-director/scripts/check-dmt.sh <project root>
```

## Change history

The full change history lives in [`CHANGELOG.md`](CHANGELOG.md) (single source; no copy is kept in this file).
