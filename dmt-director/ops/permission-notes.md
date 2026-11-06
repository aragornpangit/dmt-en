# Permission Modes and auto Re-review: Incident Evidence and Escape Hatches

## Mode re-verification (sixty-third occurrence)

A ready `agent_status` ≠ auto mode. On 2026-11-03 in bcr-nh, all three resident panes were measured sitting in the `default` mode, with 33 toolbar `ASK`s that day; the surface symptoms were "script timeout / command failure" (another pane's title read `file-claim.sh approval timeout`), while the script itself ran normally in 57ms — **the root cause was in the permission layer, the symptoms appeared in the command layer**.

- **Read argv for the verdict, not the screen**: `dmt_pane_auto_mode <pane>` judges token by token (`--permission-mode auto` / `--dangerously-skip-permissions` / `--yolo` / `--approve` / `--auto` / `-a never` / `--ask-for-approval never`); **substring matching misjudges `--autocompact auto`**, hence the token-by-token approach. rc=0 auto / 1 not auto / 2 argv unavailable.
- **Wiring**: `setup-team.sh` / `spawn-helper.sh` call `verify_auto_mode` after "ready + type skills"; rc=1 prints `WARN` + the argv, rc=2 prints `INFO` only.

**Codex as fallback harness**: skills and helper tasks are delivered with the first-round prompt of `codex -a never '<role skill prompt>'`. The first trust prompt may be confirmed manually exactly once; do not paste skill text before confirming, and rerun `setup-team.sh --harness codex --force-start` after confirming. The pane label is the role identity; the agent name is only for herdr display; the permission mode is still re-verified from argv such as `-a never` / `--ask-for-approval never`, never substituted by `agent_status`.
- **Fix**: not auto mode ⇒ `setup-team.sh --force-start` (or reopen the pane).

## auto re-review (`autoModeClassifier`): known pitfalls and current configuration

In auto mode every tool call that **requires approval** goes through one automatic re-review (the prompt is the entire session context, with a default **90s hard cap**); when the enterprise gateway is flaky / rate-limited, it ends in `no verdict ... failure=timeout` and the command is judged failed, superficially looking like "the script is broken" (measured once on 2026-11-03 with `file-claim.sh check`, while the script itself ran normally in 57ms).

The current four hardening measures (sixtieth / sixty-first occurrences): ① `dmt_harness_cmd()` in `lib-dmt.sh` prefixes codebuddy with `CODEBUDDY_AUTO_REVIEW_TIMEOUT_MS=300000` (the same key in the `env` block of the user-level `~/.codebuddy/settings.json` acts as a fallback, covering manually started sessions); ② the reviewer prefers a local model (endpoint via `DMT_LOCAL_MODEL_HOST` / `DMT_LOCAL_MODEL_PORT` in `.env`, model id `DMT_AUTO_REVIEW_LOCAL_MODEL`); ③ **health gate `auto-review-model.sh`** (runs automatically when the harness starts): probes the local endpoint, reachable ⇒ pin local, unreachable ⇒ unpin and fall back to the cbc built-in path — **pinning a model disables the built-in fallback, so this gate cannot be skipped**; `DMT_AUTO_REVIEW_GATE=off` disables the whole gate; ④ user-level `permissions.allow` covers every script under `dmt-director/scripts/` (rules only accept `Bash(<prefix>:*)`; **rules containing a `*` wildcard are judged dangerous in auto mode and ignored entirely**; commands containing redirection do not get the rule applied).

**The health gate only runs at startup**: if the endpoint dies mid-session, the active session must reopen its pane.
