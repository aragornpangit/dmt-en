# Inbox Communication

**The body goes in a file; herdr only rings the doorbell with one line.** Dispatch, reports, review verdicts, arbitration requests, and defect returns are all written to disk first, then followed by "you have a new message <file name>".

## Allowed directions

| Sender | Recipient | Direction code |
|---|---|---|
| `director` | `devm` / `anam` | `director2devm` / `director2anam` |
| `devm` / `anam` | `director` | `devm2director` / `anam2director` |
| `{role}-helper` | the main instance | `{role}-helper2{role}` (one-way, no doorbell, no return path) |

Cross-department matters are dispatched through the director. helpers have no inbox of their own.

## Writing a message

Path: project root `inbox/<recipient role>/{seq}-{direction}-{slug}-{YYMMDDHHMM}.md`.

- `{seq}` is maintained as a high-water mark by `.seq`, with no leading zeros; number assignment = max(largest number in inbox and `.doing/`, `.seq`) + 1.
- `{slug}` uses lowercase English words joined by hyphens, at most 5 words.
- The body must be self-contained: summary, authoritative paths, requested action, expected artifacts, reporting requirements.

Recommended command:

```bash
bash dmt-director/scripts/send-msg.sh <recipient role> <self> <slug> <body file>
```

## Doorbell

1. Use `herdr pane list --workspace <id>` to resolve the current pane id by `label == <recipient role>`; do not cache ids, and do not treat the herdr agent name as the role name. A Codex agent name can drift independently.
2. Send `herdr agent prompt <pane-id> 'you have a new message <file name>, in inbox/<role>/'` to the resolved pane; a return of `agent_prompted` means delivered.
3. When `agent prompt` does not accept the target or returns `agent_not_ready` / `agent_blocked`, first read `pane get` and `agent read` (read-only) to determine whether it is a trust / approval screen. If it is safely a normal input state, fall back to `pane send-text` + `send-keys enter`, then verify with `pane read`; in a blocked state, keep the message file and ask the user to handle it.

The match key is the pane `label`, not the herdr agent `name`: a Codex agent name and the pane label can differ, and the agent name drifts as sessions are rebuilt. Read the target pane before sending; if the other side has unsubmitted input, wait or ask the user to relay.

## Three states

1. Claim: `msg-take.sh <role> <file>`, which moves the file from inbox into `.doing/`.
2. Process: read the file in `.doing/`; no acknowledgement is sent.
3. Close out: `msg-done.sh <role> <file>`, which deletes it from `.doing/`.

After a restart: `*.md` in the root is unread, `.doing/` is the remaining-work list. Anything in `.doing/` not closed out for more than 24h must be reported to the direct superior. For work lasting more than 10 minutes, scan the inbox once before starting and once after finishing.

## Report on completion

`devm` / `anam` report to the director immediately when the current batch is closed out, or when blocked / timed out / in need of arbitration; the director does the same toward the user. The recipient does not acknowledge; when the sender is unsure, ask the user rather than delivering again.
