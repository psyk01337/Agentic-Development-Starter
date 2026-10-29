# Hooks Runbook

## Purpose

Hooks enforce deterministic guardrails and create an audit trail for agent tool usage.

## Runtime Contract

`.github/hooks/*.json` is the harness hook location, so `agent-policy.json` is read by the runtime, not just by this repository's scripts. Three properties of that contract decide whether the policy actually runs:

- **Input arrives on stdin as JSON.** A command hook receives `toolName` and `toolArgs` on standard input. Command-line arguments are not populated by the harness. The scripts here also accept argv so they can be exercised by hand, but fixtures must use stdin or they validate a path production never takes.
- **`preToolUse` is fail-closed.** Exit `2`, a crash, or any non-zero exit denies the tool call. A deny decision is returned as `{"permissionDecision":"deny","permissionDecisionReason":"..."}` on stdout **and** exit `2`, so the reason reaches the agent and the call is still denied if stdout is ignored.
- **Timeouts are fail-open.** A hook that exceeds `timeoutSec` is killed and the tool call proceeds through the normal permission flow. A slow hook is therefore the same as no hook, which is why every entry keeps a 10 second budget and the validator rejects anything above 30.

A malformed hook item is dropped and logged; a bad top-level `version` rejects the whole file. Both failures disable the policy silently, so `check-hook-policy` asserts the shape rather than trusting it.

## Files

- Policy: `.github/hooks/agent-policy.json` (hook wiring only, `{ "version": 1, "hooks": { ... } }`)
- Rules: `.github/hooks/policy-rules.tsv`
- Session start: `.github/hooks/scripts/session-banner.{ps1,sh}`
- Pre-tool policy: `.github/hooks/scripts/pre-tool-policy.{ps1,sh}`
- Post-tool audit: `.github/hooks/scripts/audit-log.{ps1,sh}`

Each entry declares a `bash` and a `powershell` handler. The `.sh` scripts are the POSIX handler, not a WSL extra, and the two variants must stay behaviourally identical.

## Lifecycle

1. `sessionStart`: prints banner and logs session metadata, using `sessionId` from the payload.
2. `preToolUse`: flattens the payload and blocks dangerous command patterns.
3. `postToolUse`: appends timestamped audit records.

`agent-policy.json` defines the lifecycle wiring. `policy-rules.tsv` defines the blocklist data consumed by the pre-tool policy scripts.

## Policy Metadata

The former `rolePolicyGuidance` and `logging` keys were removed from `agent-policy.json` when the file was brought into the harness schema. They are documentation, not configuration, and nothing consumed them programmatically.

- Role source of truth: `.github/roles/tool-access.json`.
- Execute-capable roles: `analysis`, `planning`, `implementation`. Command-pattern blocking matters most for these.
- `review` and `workflow-maintenance` are still subject to hooks but normally do not invoke execute tools, so use them as false-positive probes.
- The orchestration role is not execute-capable and is the only role holding `delegate-agent`; it never runs commands or edits files directly.
- Audit records are written to `.github/hooks/logs/agent-audit.log` as JSON lines.

## Blocked Patterns (Examples)

- `rm -rf`
- `del /s /q`
- `Remove-Item -Recurse -Force`
- `git reset --hard`
- `git checkout -- <path>`
- `git push --force` or `git push --force-with-lease`
- `curl | bash` (or `curl|sh`/`curl|pwsh`)
- `wget | sh`
- Remote content piped to `Invoke-Expression`
- `chmod -R 777`
- `git clean -f` (also `-fd`, `-fdx`, or `--force`)
- `git checkout .` or `git restore .` (discard-all working tree)
- `git stash drop` or `git stash clear`
- `git branch -D`
- `rmdir /s /q` or `rd /s /q`
- `docker compose down -v` (teardown with volume deletion)
- `docker volume prune` or `docker system prune`
- `git add .env` or staging common credential files (`.pem`, `.key`, `.npmrc`, `id_rsa`)
- Writing likely real secrets/tokens into `.env`, including common credential names such as `secret=`, `api_key=`, and cloud credential variables
- `pip install --trusted-host` or `pip install --index-url http://` (TLS bypass for package sources)
- `npm install --registry http://` (plain HTTP npm registry)
- Unapproved edits to core policy files when the command explicitly says the edit is unapproved

## What Hooks Can Enforce

- Block tool calls whose command string matches a deterministic unsafe pattern.
- Require safer alternatives for common destructive or supply-chain-risky commands.
- Create audit records for tool usage when the runtime invokes the hooks.
- Deny by exit code, so the refusal holds even if the agent ignores the message.

## What Hooks Cannot Enforce

- They cannot understand every intent behind a command.
- They cannot protect tools or runtimes that do not invoke the hook lifecycle.
- They cannot block work when they are slow: timeouts fail open.
- They cannot judge intent. The engine gate below bounds *which files* may change, but a hook never sees a plan or a reason, only calls.
- They cannot replace human review for high-risk policy, MCP, credential, or deployment changes.
- They cannot guarantee secrets are absent from every external system or terminal output.

## Engine Gate

`pre-tool-policy.{sh,ps1}` consults `agentic_engine.py` after the rule loop, and only when a run exists:

```
.agentic/state missing        -> allow, no engine call at all
.agentic/state present        -> run `python3 agentic_engine.py check-tool` with the payload on stdin
  tool not classified         -> deny
  stage forbids the tool kind -> deny
  write outside the write set -> deny
  engine unreachable          -> deny
```

Three properties make this safe to leave enabled:

- **Inert without a run.** No `.agentic/state`, no subprocess, no behaviour change, no latency cost.
- **Finished runs release the session.** Stages `done` and `blocked` are not active, so a completed run never locks anyone out.
- **Tool names come from `.github/roles/tool-access.json`.** The gate inverts `toolDefinitions` at runtime rather than owning a private copy, so it cannot drift from the vocabulary the supervisor validator already checks.

The design, its risks, and its unverified status are recorded in `docs/adr/0009-hook-governed-loop.md`.

## If a Command Is Blocked

1. Read the block reason and safer alternative printed by the hook.
2. Replace destructive/unsafe command with explicit, reviewable steps.
3. Re-run with minimal privileges and narrower scope.

## Extending Policy

1. Add or adjust a line in `.github/hooks/policy-rules.tsv`.
2. Keep the regex narrow enough to avoid noisy false positives.
3. Provide a specific safer alternative, not just a generic warning.
4. Change both the `.sh` and `.ps1` variants only when the hook mechanism changes, not when only the rule data changes.
5. Add a denied fixture and at least one safe allowed fixture to `.github/scripts/check-hook-policy.*`. Fixtures are delivered as stdin JSON because that is how the harness calls the hook.
6. Run `.github/scripts/check-hook-policy.sh` and `.github/scripts/check-hook-policy.ps1` before merging.
7. Matching is case-insensitive by default; use a scoped `(?-i:...)` group when a rule must distinguish case (for example, blocking `git branch -D` while allowing `git branch -d`).

Rules match against the payload with JSON punctuation flattened to spaces, so an anchor such as `(^|\s)` still matches a command that arrives inside a JSON string. Write patterns against the command text, not against JSON syntax.

## Policy Test Fixtures

Denied fixtures cover destructive deletion (including `git clean -f`, discard-all restores, `rmdir /s /q`, and Docker prunes), remote shell execution, hard reset, force push, stash and branch destruction, secret-file staging, secret writes to `.env`, HTTP package registries, and unapproved policy edits.

Allowed fixtures cover common safe commands such as `git status --short`, `git diff --stat`, local test commands, and starter validation scripts.

## Debug False Positives

1. Copy the exact blocked command.
2. Identify the matching regex in `.github/hooks/policy-rules.tsv`.
3. Decide whether the command is actually safe or whether the safer alternative should be used.
4. If the rule is too broad, narrow the regex and add a regression fixture.
5. If the command is high-risk but necessary, require documented approval instead of weakening the rule globally.

## Emergency Bypass

Bypass should be rare and explicit:

- Record who approved the bypass, why it was needed, and what command or action was allowed.
- Prefer a one-time local bypass over changing shared policy.
- Open follow-up workflow debt to add a safer supported path.
- Never bypass secret-handling, credential, or production-data safeguards just to save time.

### Role-Aware Tuning Guidance

- Treat `preToolUse` rules as global safety rails, then tune rule wording with the highest-risk execution roles in mind.
- Use `.github/roles/tool-access.json` as the source of truth for which roles can run execute tools.
- If a rule primarily targets command execution risk, verify its impact for `analysis`, `planning`, and `implementation` roles first.
- Keep `review` and `workflow-maintenance` roles in mind for false-positive checks, since they usually do not run execute tools.
- If a policy change alters expected behavior for a role, update both this runbook and the related role notes in `.github/hooks/agent-policy.json`.

The approval-gated orchestration overlay should reuse the existing `postToolUse` audit seam for transition records. It should not add new core hook lifecycle phases.

## Audit Log Usage

- Logs are written to `.github/hooks/logs/agent-audit.log` as JSON lines.
- Each record carries `tool`, `sessionId`, `action`, and `result`.
- `action` is truncated to 160 characters and secret-shaped values are replaced with `[REDACTED]` before anything is written; the record is escaped so every line stays parseable JSON.
- Redaction is best-effort pattern matching, not a guarantee. Treat the log as sensitive, never paste it into an issue or PR, and never add raw request bodies, headers, or credentials to it.
- Use logs for debugging, policy tuning, and review traceability.

## Troubleshooting

- **Every tool call is denied.** A `preToolUse` hook that cannot run fails closed. Check that the referenced script path exists and that `pwsh` or `bash` is on `PATH`; the validator asserts referenced scripts exist for this reason.
- **Nothing is blocked.** The policy is not loading. Confirm `version` is the number `1` and every item has `type: "command"` and a string handler. A bad version rejects the whole file and a malformed item is dropped, both without stopping the session.
- **Blocking is intermittent.** A slow hook times out, and a timeout is fail-open. Keep the script's own work small and leave `timeoutSec` at 10.
- **A rule never fires.** The rule may be anchored against content the flattening step removed. Test the exact payload through `check-hook-policy` rather than the command string alone.
- **Every tool call is denied and `.agentic/state` exists.** The engine gate is failing closed. Check that `python3` or `python` is on `PATH`, that `.github/roles/tool-access.json` is present, and that the tool name in the payload is listed in its `toolDefinitions`. A finished or blocked run is ignored, so a stale `done` state file is never the cause.

