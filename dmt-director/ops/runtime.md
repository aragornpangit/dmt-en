# pane Runtime and Lifecycle

**Identity = pane label, not position, not tab.** Each resident role occupies one pane (`director` / `devm` / `anam`); `{role}-helper` is an on-demand pane; `pde{n}` / `dev-e` / `ana-e` / `reviewer{n}` are subagents and do not occupy a pane.

## Layout

- `devm` lives inside the `director` tab, to the right of the director pane; `anam` gets its own tab; labels match role names and are unique across the whole workspace.
- Identify partners by the `label` from `herdr pane list`; never by tab position, never by remembered pane id. Missing label ⇒ stop and ask the user.
- `devm` must not identify itself by tab label (its tab label is `director`).
- **`herdr tab close` is forbidden**: the director tab would take devm down with it, and helper tabs must be kept for reuse; close panes only.

## Startup

After the user has prepared the `director` tab and started the harness (add `--harness codex` when Codex is the fallback):

```bash
bash dmt-director/scripts/setup-team.sh --harness codex
```

The script idempotently: renames director → splits `devm` → creates the `anam` tab → starts the harness on its behalf → types the skill command. Codex skills are delivered in one shot with the first-round prompt; if a trust screen appears at startup, confirm it manually first, then rerun `setup-team.sh --harness codex --force-start`. After skill names / install locations change, run `setup-team.sh --reload`; for Codex, reopen the pane instead.

The readiness criterion is `agent_status` from `herdr pane get <pane>` not being `unknown`. After startup you must re-verify auto mode by reading back argv with `dmt_pane_auto_mode`; whether the role skill loaded correctly is verified with that role's actual artifacts and the skill receipt. On seeing `WARN`, reopen with `setup-team.sh --force-start`. For incidents and escape hatches see [`permission-notes.md`](permission-notes.md).

## Manual session permissions

User-started sessions only: press `shift+Tab` to switch to `auto mode` before sending the first message. The permission mode is locked once the session starts; panes started on your behalf do not go through this flow.

## Codex differences

- Codex discovers project skills from `.agents/skills/` and `.codex/skills/`; DMT role skills are bare names like `dmt-dm`, while mattpocock plugin skills are referenced by qualified name `mattpocock-skills:<name>`.
- Pane roles are identified only by `label`. When sending a doorbell, first resolve the pane id by label, then send `agent prompt` to that pane; a Codex agent name can drift independently and must not serve as role identity.
- When Codex shows a trust / startup screen during launch, `agent_status` may still be `unknown` or `blocked`. Wait for manual confirmation, then rerun the stage; do not paste skill text into the confirmation screen.
- Codex's native subagent interface appears according to the current user configuration and may be absent. When `spawn_agent` is missing, DMT in that herdr session only does the role work of its own pane; it does not fake nested panes or self-create agents through `codex exec`.
- The mattpocock Codex plugin is the install source; if a compatible copy also exists under `~/.codex/skills`, pick one at the same version before startup to avoid registering duplicate same-name skills.

## helper lifecycle

How helpers are opened, their semantics, and reclamation are all in [`helper.md`](helper.md).
