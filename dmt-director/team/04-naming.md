## 2. File naming conventions (authoritative)

Sequence numbers are independent per artifact category and self-accumulating within a category (starting at 001): `{prd-seq}` (PRD), `{research-seq}` (research report), `{human-arch-seq}` (human architecture), `{human-plan-seq}` (human plan), `{spec-seq}` (SPEC); **tickets use the two-level composite `{ticket-seq}` = `{spec-seq}.{NN}`** (Rules 1–2); inbox messages use a separate `{seq}` message serial number. `{slug}` is a short semantic slug (lowercase English, hyphens, no more than 5 words), `{YYMMDD-HHMM}` is date and time, `v{N}` is the version number for in-place upgrades of the same file.

| Artifact | Directory | File name |
|---|---|---|
| Research report | `docs/analyst/` | `{research-seq}-research-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Product requirements document (PRD) | `docs/pd/prd/` | `{prd-seq}-prd-{slug}-{YYMMDD}-v{N}.md` |
| Specification (SPEC) | `docs/pd/spec/` | `{spec-seq}-spec-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Development ticket | `docs/dev/tickets/` | `{spec-seq}.{NN}-ticket-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Human architecture | `docs/human/human-arch/` | `{human-arch-seq}-arch-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Human plan | `docs/human/human-plan/` | `{human-plan-seq}-plan-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Inbox message | `inbox/<recipient role>/` | `{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (no version number; claimed into `.doing/`, deleted when done) |

**Codex invocation name**: DMT roles stay bare names (`dmt-dm`); mattpocock plugin skills use the qualified name (`mattpocock-skills:code-review`). Panes and the inbox keep using the runtime id; the herdr agent name takes no part in naming.

Rules:

1. **SPEC number**: a SPEC uses the plain `{spec-seq}` (the "chain" anchor of one requirement). A ticket's number is the two-level composite **`{spec-seq}.{NN}`**: `.` is a hierarchy separator (not a decimal point, not a version number); the first part is the owning SPEC's number, the second is the NNth ticket under that SPEC. Example `089.02` = the 2nd ticket of SPEC-089. Tickets no longer occupy a plain `{spec-seq}`; every ticket states `Corresponding SPEC: {seq}` explicitly instead of relying on an implicit same-number link.
2. **NN scope**: `NN` starts at `01` and **increments only within the same spec-seq**; each SPEC counts independently, and a voided ticket's `NN` is never reused. The first ticket also carries an `NN` (no "first-ticket exception"); a historical first ticket without `NN` counts as `.01`, so the next new ticket starts at `.02`. Tickets with no parent SPEC (gate governance, evidence collection, errata, audit fixes) keep the global `{spec-seq}-ticket-{slug}-{YYMMDD-HHMM}--v{N}.md` form — no `.`, a separate namespace; claiming a number still requires the three-directory scan with the DM as the sole gate.
3. **Version semantics**: small updates within a version **change the same file in place**; a substantive revision **creates a new versioned file** (new timestamp, `v{N+1}`) and marks the head of the old file in place with "superseded by v N+1".
4. A PRD carries only the date (`YYMMDD`) in the format the requester specifies, with no time; every other artifact always carries a time.
5. Historical files are never renamed; new artifacts are named only per this table. The historical `-NN` form (`089-02`, `103-01`, `056-02`) is **not** equivalent to the new `.NN` form — do not convert, deduplicate or merge across them. Bare numbers and `-NN` references in branch names, tool directories and evidence directories stay as they are; record the mapping on the ticket face instead.
