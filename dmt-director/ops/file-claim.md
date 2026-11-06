# File Occupancy

Before any role edits (writes / appends / deletes) any file, occupancy must be checked first; only edit once you hold it, and release it immediately after editing.

```bash
bash dmt-director/scripts/file-claim.sh check|claim|release <path> <owner>
bash dmt-director/scripts/file-claim.sh list
```

- Records land in `locks/` at the root of the main worktree; writes from inside a worktree also go back to the main tree. `<owner>` uses "role:instance", e.g. `devm-helper`.
- `rc=3` ⇒ stop: wait for release, switch files, or report to a superior; never bypass it, never delete someone else's lock.
- TTL 30 minutes. An expired lock may be taken over, but the report must state "took over expired lock `<path>` (original holder `<owner>`)"; re-`claim` to extend before finishing a long task.
- `inbox/` and `locks/` themselves are not registered; worktrees are not exempt.
