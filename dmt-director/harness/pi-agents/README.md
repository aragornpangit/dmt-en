# pi subagent agent definition templates (the four dmt subagent roles)

pi's `delegate` subagent defaults to `inheritSkills: false` (no skill list, no Skill tool). This directory gives each of dmt's four **subagent roles** an agent definition template, using `inheritSkills: false` plus a `skills:` **exact allowlist** to inject "the role skill + that role's mandatory skills" into the subagent.

> Mechanism and test results: [`../pi.md`](../pi.md) §4.1; the mandatory skill list: [`../../team/03-comms.md`](../../team/03-comms.md) §1.4.

## Usage

`install-skills.sh --harness pi` lays this directory out into the target project's **`.pi/agents/`**. When dispatching, fill the `agent` field with the corresponding definition name (no longer `delegate`):

```js
await runs.run({ agent: "dmt-dev-e",  prompt: "You are devm's dev-e subagent. Ticket: ..." });
await runs.run({ agent: "dmt-ana-e", prompt: "You are anam's ana-e subagent. Unit: ..." });
await runs.run({ agent: "dmt-pde",   prompt: "You are director's pde1 subagent. Unit: ..." });
await runs.run({ agent: "dmt-reviewer", prompt: "You are devm's reviewer1 subagent. Ticket: ..." });
```

**When the agent definitions are not installed**, the fallback path is still `delegate` plus a prompt giving absolute paths (see `../pi.md` §4.3).

## Definition list

| File | agent name | Role skill | Preselected mandatory skills |
|---|---|---|---|
| [`dmt-dev-e.md`](dmt-dev-e.md) | `dmt-dev-e` | `dmt-de` | `tdd`, `implement`, `code-review`, `diagnosing-bugs` |
| [`dmt-ana-e.md`](dmt-ana-e.md) | `dmt-ana-e` | `dmt-ae` | `research`, `grilling`, `grill-me`, `grill-with-docs` |
| [`dmt-pde.md`](dmt-pde.md) | `dmt-pde` | `dmt-pde` | `grilling`, `research`, `to-spec`, `to-tickets` |
| [`dmt-reviewer.md`](dmt-reviewer.md) | `dmt-reviewer` | `dmt-reviewer` | `code-review` |

`ana-e`'s `/rea` on pi is an **MCP tool** (`mcp__rea`), not a skill, so it is not listed in `skills:` (add `mcp:rea` to `tools:` when needed, or let the tool be available automatically).
