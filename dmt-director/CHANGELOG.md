# dmt team contract · changelog (English mirror)

> **Version `5.18.8` · 2026-11-06** — same number as the `version:` field in the seven role `SKILL.md` files.
> This file records only the **English-mirror history**; the full, item-by-item history (87 entries, Chinese) lives in the
> upstream [`dmt`](https://github.com/aragornpangit/dmt) repository under `dmt-director/CHANGELOG.md`, and its semantic digest in
> `CHANGELOG-DIGEST.md`. Entries are facts as of their date and are never rewritten or renumbered.

- **2026-11-06（sync `dmt-en` to upstream `5.18.8` — full English parity）**：
  the mirror was brought from `5.7.1` (4 skills) to `5.18.8` (7 skills) in one migration.
  ① **Skills** — added `dmt-de`, `dmt-ae`, `dmt-reviewer`; rewrote all seven `SKILL.md` from the current upstream source
  (including the new "## 0. Load per harness" section).
  ② **Harness layer (new)** — `harness/COMMON.md` plus one delta file per harness (`pi`, `codebuddy`, `claude`, `codex`,
  `opencode`), `harness/README.md`, `harness/BACKLOG.md`, and `harness/pi-agents/` (four allowlisted pi agent definitions:
  `dmt-dev-e`, `dmt-ana-e`, `dmt-pde`, `dmt-reviewer`).
  ③ **Machine-readable layer (new)** — `dmt_contract.yaml` (with `harness_docs`, `harness_loading`, `harness_forwarding`,
  `pi_capability_gap`) and `harness_matrix.yaml`; the checker `scripts/check-dmt.sh` now runs its A6b harness assertions
  against English content strings.
  ④ **Team layer** — `team.md` plus twelve `team/*.md` files, and six `ops/*.md` files, all in English.
  ⑤ **Scripts** — replaced by the upstream 5.18.5 set (21 scripts; comments remain in the upstream language).
  ⑥ **Reports** — `logs/2026-11-06-harness-test-report.md` (English) records the five-harness end-to-end results
  and the two hard codex constraints (`--sandbox danger-full-access`, stale `HERDR_*` shell environment).
  **Machine check**: `ALL_PASS`.

- **2026-10-27（`5.7.1` — previous English mirror baseline）**：
  four skills (`dmt-director`, `dmt-dm`, `dmt-am`, `dmt-pde`), no `harness/` layer, no `dmt_contract.yaml`.
  Push / merge ownership assigned to devm; helper gained pure-clone semantics; added the "Scope" note clarifying that
  write/push ownership constrains the dmt-managed target project only, not maintenance of the skill repositories themselves.
