## 7. Machine check

**Single entry point** (P5: the structure and content groups merged into one, run in one place):

```bash
bash dmt-director/scripts/check-dmt.sh <project root>
```

When maintaining the dmt repo itself, the skill originals sit at the repo root rather than in `.agents/skills`:

```bash
DMT_SKILLS_DIR="$PWD" bash dmt-director/scripts/check-dmt.sh "$PWD"
```

Two assertion groups, both fed from **single sources** (P1: no more scattered Chinese greps):

- **A. Structural assertions** — read `dmt-director/dmt_contract.yaml` (skill list / version source / artifact directories / organization / script list / abolished scripts) and `dmt-director/harness_matrix.yaml` (the five-harness matrix). Checks: A1 same version number, A2 all seven skills present, A3 artifact / runtime directories, A4 scripts complete + abolished scripts not resurrected, A5 matrix complete, A6 single-source discipline (every skill points at team.md), A6b load by harness (`harness/` files complete + keys match the matrix + all seven skills have step 0 + `harness-detect.sh` self-test over five harnesses with unknown rc=1).
- **B. Content assertions** — read the `content_assertions` table in `dmt_contract.yaml` (`group → file → require / forbid`). Prefer structural assertions and use short strings only where structuring is impossible.

**A rerun is mandatory after changing any of the following**: path conventions, pane lifecycle, parallelism policy, role hierarchy, write permissions, mandatory skills, file claims, review gates, general skills, skill links, inbox three states, dispatch prompt file-writing discipline, pi agent-name hosting, script interfaces, **harness differences / skill loading entry points (`harness/` + `harness-detect.sh`)**.

**Maintenance**: skill, organization and script changes go into `dmt_contract.yaml`; discipline changes go into the matching `team/*.md`, syncing short assertions only when necessary.
