## 2. File naming conventions (authoritative)

Sequence numbers are independent per artifact category and self-accumulating within a category (starting at 001): `{prd-seq}` (PRD), `{research-seq}` (research report), `{human-arch-seq}` (human architecture), `{human-plan-seq}` (human plan), `{spec-seq}` (shared by SPEC and ticket); inbox messages use a separate `{seq}` message serial number. `{slug}` is a short semantic slug (lowercase English, hyphens, no more than 5 words), `{YYMMDD-HHMM}` is date and time, `v{N}` is the version number for in-place upgrades of the same file.

| Artifact | Directory | File name |
|---|---|---|
| Research report | `docs/analyst/` | `{research-seq}-research-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Product requirements document (PRD) | `docs/pd/prd/` | `{prd-seq}-prd-{slug}-{YYMMDD}-v{N}.md` |
| Specification (SPEC) | `docs/pd/spec/` | `{spec-seq}-spec-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Development ticket | `docs/dev/tickets/` | `{spec-seq}-ticket-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Human architecture | `docs/human/human-arch/` | `{human-arch-seq}-arch-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Human plan | `docs/human/human-plan/` | `{human-plan-seq}-plan-{slug}-{YYMMDD-HHMM}--v{N}.md` |
| Inbox message | `inbox/<recipient role>/` | `{seq}-{direction}-{slug}-{YYMMDDHHMM}.md` (no version number; claimed into `.doing/`, deleted when done) |

**Codex invocation name**: DMT roles stay bare names (`dmt-dm`); mattpocock plugin skills use the qualified name (`mattpocock-skills:code-review`). Panes and the inbox keep using the runtime id; the herdr agent name takes no part in naming.

Rules:

1. **The SPEC and its tickets must align on `spec-seq`**: the SPEC for a requirement and its tickets share the same `spec-seq` prefix.
2. **Version semantics**: small updates within a version **change the same file in place**; a substantive revision **creates a new versioned file** (new timestamp, `v{N+1}`) and marks the head of the old file in place with "superseded by v N+1".
3. A PRD carries only the date (`YYMMDD`) in the format the requester specifies, with no time; every other artifact always carries a time.
4. Historical files are never renamed; new artifacts are named only per this table.
