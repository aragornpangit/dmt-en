# helper Clones

A helper is a temporary pure clone of a resident pane role; at most one per role, it does not occupy a new role and does not create an independent channel.

## How to open one

The only criterion: the main-instance pane has `agent_status == working` and pending work has gone unprocessed for more than 10 minutes.

```bash
bash dmt-director/scripts/spawn-helper.sh <director|devm|anam> "<task>"
```

The script creates or reuses the shared `helper` tab and splits out `{role}-helper`. The task is delivered once at spawn time; after that no input-box content is accepted.

## Semantics

- Same skill as the main instance.
- No inbox of its own, receives no messages, does not use the doorbell.
- Results are written back one-way into `inbox/<main instance>/` using `helper-report.sh <main instance> <body file>`.
- Exclusive actions are not handed over: hardware device write operations belong to the `devm` / `director` main instances; merge / push belong to the `devm` main instance.

## Reclamation

Close the pane immediately after the task is closed out:

```bash
bash dmt-director/scripts/close-helper.sh <director|devm|anam>
```

Preconditions for closing: results have been recorded in the ledger; any worktrees under its name have been removed; messages in that helper's direction in the main instance's inbox have been closed out. Keep the helper tab for reuse; closing the tab is forbidden.
