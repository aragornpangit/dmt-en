## 3. Directory responsibilities

**The only places artifacts may land (with owner and alignment requirements)**:

| Sole directory | Owner | Artifact | Alignment requirement |
|---|---|---|---|
| `docs/pd/prd/` | `pde{n}` (drafter) / director (finalizer) | Product requirements document (PRD) | independent `{prd-seq}` numbering |
| `docs/pd/spec/` | `pde{n}` (drafter) / director (finalizer) | Product specification (SPEC, including acceptance criteria) | shares `spec-seq` with tickets |
| `docs/dev/tickets/` | `pde{n}` (drafter) / director (ticket numbering and finalization); devm only appends an "Implementation status" section at the end of the ticket | Development ticket | shares `spec-seq` with the SPEC |
| `docs/analyst/` | anam | Market research and competitor reverse-engineering reports | none |
| `docs/analyst/evidence/{research-seq}-{slug}/` | anam | Primary research evidence (sampling output / raw logs / manifest) | same number as the report; must ship `manifest.txt` (file name + size + sha256 + sampling command) |
| `docs/human/human-arch/` | director | Human architecture document | none |
| `docs/human/human-plan/` | director | Human plan document | none |
| `dmt-director/team.md` (the original; `install-skills.sh` symlinks `team.md` and `OPS.md` into `docs/`, and the files under `ops/` into `docs/ops/`) | director | Team contract (this file; after installation the entry point is `docs/team.md`) | the symlink follows the original (except in `--copy` mode) |
| `docs/handoff/` | director / devm | Hand-off notes (`{director,devm}-{slug}-{YYMMDD-HHMM}-v{N}.md`; **spot-check / re-verification verdicts may also be written here**); in other cases write only when the user asks | none |
| `inbox/<recipient role>/` | written by the sender, deleted by the recipient after reading | Inter-role messages (runtime channel, **not committed**, **at the project root, not under `docs/`**) | direction and `{seq}` per [`dmt-director/ops/comms.md`](../ops/comms.md) |

1. The paths above are the **only permitted locations**; never write to `docs/pd/` (other than `prd/`, `spec/`), `docs/dev/` (other than `tickets/`), `docs/human/` (other than `human-arch/`, `human-plan/`), `docs/test/` or anywhere else; the inbox lives only under `inbox/` at the project root and never goes into `docs/`; do not create new document directories of your own.
2. Each department's artifact directories **stay strictly separate**: read-only references are fine, moving or renaming is not.
3. **Engineers and `reviewer{n}` do not write to `docs/`**: they report through the sub-agent return value; evidence is merged into the ticket / report by their superior.
4. Legacy directories keep history only and accept no new artifacts; the current landing rules are in the table above.
5. **Directory initialization is the director's job**: when taking over a project the director checks first and fills the gaps (see §3.1); artifact directories are not created by anam / devm themselves.
6. The machine check does not validate individual file paths; the table above plus review are what keep new artifacts in line.

### 3.1 Initialization (director's job, idempotent)

The **first thing** the director does when taking over a project: check the directories and create whatever is missing. Safe to repeat; anything already there is left untouched:

```bash
bash dmt-director/scripts/init-project.sh <project root>   # omit the argument to use the current directory
```

The script does three things: creates the six artifact directories plus three inboxes (`inbox/director/`, `inbox/devm/`, `inbox/anam/`) and `locks/`; adds `inbox/*/`, `locks/`, `.codebuddy/` to `.gitignore` (skipped if already present); and runs the machine check until `ALL_PASS`.

- **Done criterion**: the machine check prints `ALL_PASS`. When a directory is missing the script reports `FAIL directory missing`; the director fills the gap and reruns.
- **Directories only, no artifacts**: empty directories get no placeholder files, so they are never mistaken for existing deliverables.
- **`locks/` is a runtime channel**: file claim registration is described in [`dmt-director/ops/file-claim.md`](../ops/file-claim.md) and is not committed.
- **anam / devm do not create artifact directories**: if their target directory is missing they report to the director (inbox directories are a runtime channel and may be created on demand with `mkdir -p` as a fallback).
- The contract file `dmt-director/team.md` and skill installation are not part of this step (see `README.md` for installation).
