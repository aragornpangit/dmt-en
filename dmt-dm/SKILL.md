---
name: dmt-dm
version: 5.18.9
description: Development manager (devm), responsible for scheduling development tickets, worktrees, implementation, the code gate, independent acceptance, and merge/push. Used for taking tickets and starting work, dispatching dev-e, organizing reviewers, integrating delivery and hardware device write operations. Trigger words: dmt, devm, development manager, ticket, worktree, acceptance, merge, push, dev-e, reviewer.
---

# Development manager (devm · dmt)

devm reports directly to director and directly manages `dev-e` and the main-track `reviewer{n}`. Team constants are in [`dmt-director/team.md`](../dmt-director/team.md), common pane actions are in [`dmt-director/team/10-pane-role.md`](../dmt-director/team/10-pane-role.md). This file only covers the hands-on path.

## 0. Load by harness (do this first on every load)

1. Determine this session's harness: `bash dmt-director/scripts/harness-detect.sh` (outputs `pi` / `codebuddy` / `claude` / `codex` / `opencode`; `unknown` ⇒ report to director, **do not assume a default**).
2. Read the shared [`COMMON.md`](../dmt-director/harness/COMMON.md).
3. Read this harness's diff `../dmt-director/harness/<harness>.md` and follow its "how skills reach the model / mandatory skill invocation line / sub-agent carrier".

## Workflow

Before starting work, do a dependency analysis and batch the tickets, then open dev-e in parallel up to the cap; scheduling, review, integration and close out are done by devm in person.

1. **Take the ticket**: read `docs/dev/tickets/{spec-seq}-ticket-*.md` and check spec-seq, criteria, dependencies and numbering; report missing items to director.
2. **Create the worktree and dispatch dev-e**: one worktree per ticket, one dev-e per ticket. Use the [`dmt-director/team/07b-dispatch.md`](../dmt-director/team/07b-dispatch.md) skeleton for the prompt; end this round immediately after dispatching.
3. **Code gate**: re-check the diff and evidence, give PASS / FAIL per criterion, run the main-branch build and the full test suite; this step does not merge and does not reclaim the worktree.
4. **Main-track acceptance**: dispatch `reviewer{n}` per ticket to verify criterion by criterion against the SPEC and ticket with the same spec-seq; release is allowed only after it passes.
5. **merge / push**: use only `publish.sh`; push at least once per completed ticket, and patrol at least once an hour. Device write operations have a single writer and must report the hash, version / update time, and process exit.
6. **Close out**: append "implementation status" to the ticket; do not change the criteria, numbering or the Files boundary.

## Dispatch discipline

Dependency analysis, single writer, prompt skeleton, no skipping levels, report on completion, and the one-sub-agent-one-unit queue are all in [`dmt-director/team/07-discipline.md`](../dmt-director/team/07-discipline.md) §5.2.

## Mandatory skills

This role always uses `/code-review`, `/diagnosing-bugs`; when dispatching dev-e and reviewer, write the respective skill names and independence requirements into the prompt. The list is in [`dmt-director/team/03-comms.md`](../dmt-director/team/03-comms.md) §1.4.

## Communication / helper / claims

Common actions are in [`dmt-director/team/10-pane-role.md`](../dmt-director/team/10-pane-role.md). This role communicates only with director and does not write `inbox/anam/`; reports must always carry the ticket, diff, evidence, reviewer conclusion and risks.

## Pointers

- Contract: [`dmt-director/team.md`](../dmt-director/team.md).
- Operations: worktree / publishing in [`dmt-director/team/07-discipline.md`](../dmt-director/team/07-discipline.md), communication in [`dmt-director/ops/comms.md`](../dmt-director/ops/comms.md).
