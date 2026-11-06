### 1.2 Runtime environment and pane lifecycle

**Operating details: see [`dmt-director/ops/runtime.md`](../ops/runtime.md)** — pane/tab shapes, startup, permissions and helper lifecycle.

**Harness compatibility**:

| harness | Skill discovery directories (measured; `<project>/` project-level, `~/` user-level) | Launch command on the role's behalf | Skill invocation line |
|---|---|---|---|
| `claude` | project-level `.claude/skills/`; user-level `~/.claude/skills/` | `claude --permission-mode auto` | `/dmt-dm` |
| `codebuddy` | project-level `.codebuddy/skills/`; user-level `~/.codebuddy/skills/` | `codebuddy --permission-mode auto` | `/dmt-dm` |
| `codex` | project-level `.agents/skills/`, `.codex/skills/`; user-level `~/.agents/skills/`, `~/.codex/skills/` | `codex -a never '<role skill prompt>'` | `/dmt-dm`; plugin skills `mattpocock-skills:<name>` |
| `opencode` | project-level `.agents/skills/`, `.claude/skills/`, `.opencode/skills/` (**plural**); user-level `~/.agents/skills/`, `~/.claude/skills/` | `opencode --auto` | `/dmt-dm` |
| `pi` | project-level `.agents/skills/`, `.pi/skills/`; user-level `~/.agents/skills/`, `~/.pi/agent/skills/` (**not `~/.pi/skills/`**) | `pi --approve` | **`/skill:dmt-dm`** |

**Constraints**:

1. Skill invocation always goes through `lib-dmt.sh: dmt_skill_cmd`; pi uses `/skill:<name>`, everything else uses `/<name>`. Codex plugin skills additionally go through `dmt_skill_ref` to produce the qualified name.
2. `install-skills.sh` installs to three places by default: `.agents/skills/`, `.claude/skills/`, `.codebuddy/skills/`; installing only one leaves harnesses uncovered.
3. The first time Codex enters a project, trust must be confirmed by hand; its skill and helper tasks must be delivered along with the first-round prompt. pi must be started with `--approve`.
4. After startup, re-verify auto mode by reading argv with `dmt_pane_auto_mode`; verify that the role skill loaded correctly from that role's actual artifacts and receipts. If it is not in auto mode, restart with `setup-team.sh --force-start`. Incident details: [`dmt-director/ops/permission-notes.md`](../ops/permission-notes.md).
5. A Codex agent name is not the role identity; the doorbell resolves its target by pane label only, and sends an `agent prompt` or pane input to the pane.

**Skill loading (one file per harness)**: the notes on "skill discovery directories / startup and permissions / skill invocation line / how skills reach the model / sub-agent hosting" live in [`../harness/README.md`](../harness/README.md) — the **common part** in [`../harness/COMMON.md`](../harness/COMMON.md) plus **one difference file per harness** ([`pi.md`](../harness/pi.md) / [`codebuddy.md`](../harness/codebuddy.md) / [`claude.md`](../harness/claude.md) / [`codex.md`](../harness/codex.md) / [`opencode.md`](../harness/opencode.md)).

The "## 0. Load by harness" section of the seven role `SKILL.md` files is the **sole entry point**: first run `bash dmt-director/scripts/harness-detect.sh` to determine this session's harness (it returns `unknown` with rc=1 when it cannot tell, and **you must not assume a default**), then read the common part plus this harness's difference file.
