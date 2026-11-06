# §10 Common actions for pane roles (shared by the three pane skills `director` / `devm` / `anam`; per-role differences are given in one line inside each skill)

> The three pane skills (`dmt-director` / `dmt-dm` / `dmt-am`) are **fully isomorphic** on the four items **identity and pane, communication, helper, file claims**; only the role name / direction code / reporting line differ. This file holds the common part; each skill writes just the one "differences for this role" line.

## Identity and pane (details in [`dmt-director/ops/runtime.md`](../ops/runtime.md))

- **Identity = pane label**: the role name equals your own pane label and is unique across the workspace; **do not identify yourself by tab position and do not remember pane ids** (they change on restart). Startup self-check: if the label from `herdr pane get "$HERDR_PANE_ID"` does not match, self-heal with `pane rename`.
- **Do not create tabs / panes yourself** (the only exception: create the team-wide `helper` tab when it does not exist); `director` is exempt (it creates the `devm` / `anam` panes, see its skill).
- **The skill invocation line is generated per harness** (`team.md` §1.2): `/<skill name>` for claude / codebuddy / codex / opencode, **`/skill:<skill name>` for pi**; always go through `dmt_skill_cmd` in `lib-dmt.sh` and **do not type the prefix by hand** (a mistake fails silently on the harnesses above).

## Communication / helper / claims

See [`dmt-director/ops/comms.md`](../ops/comms.md), [`dmt-director/ops/helper.md`](../ops/helper.md) and [`dmt-director/ops/file-claim.md`](../ops/file-claim.md) respectively. This page does not restate the operating steps.

## Closing out

**Report on completion**: as soon as this batch closes out (or is blocked / times out / needs arbitration), report **immediately** to your direct superior (inbox body + doorbell); do not hang silently. **Every report must carry**: the goal / conclusion in one sentence, artifact paths, evidence sources, and open items.
