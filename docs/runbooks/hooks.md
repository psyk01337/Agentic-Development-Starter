# Hooks Runbook

## Purpose

Hooks enforce deterministic guardrails and create an audit trail for agent tool usage.

## Files

- Policy: `.github/hooks/agent-policy.json`
- Rules: `.github/hooks/policy-rules.tsv`
- Session start: `.github/hooks/scripts/session-banner.ps1`
- Pre-tool policy: `.github/hooks/scripts/pre-tool-policy.ps1`
- Post-tool audit: `.github/hooks/scripts/audit-log.ps1`
- Optional WSL scripts: `.github/hooks/scripts/*.sh`

## Lifecycle

1. `sessionStart`: prints banner and logs session metadata.
2. `preToolUse`: inspects pending tool action/command and blocks dangerous patterns.
3. `postToolUse`: appends timestamped audit records.

`agent-policy.json` defines the lifecycle wiring. `policy-rules.tsv` defines the blocklist data consumed by the pre-tool policy scripts.

Role applicability is documented in `.github/hooks/agent-policy.json` under `rolePolicyGuidance` and should stay aligned with `.github/roles/tool-access.json`.

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
- Writing likely real secrets/tokens into `.env`
- `pip install --trusted-host` or `pip install --index-url http://` (TLS bypass for package sources)
- `npm install --registry http://` (plain HTTP npm registry)
- Unapproved edits to core policy files when the command explicitly says the edit is unapproved

## What Hooks Can Enforce

- Block command strings that match deterministic unsafe patterns.
- Require safer alternatives for common destructive or supply-chain-risky commands.
- Create audit records for tool usage when the runtime invokes the hooks.
- Provide consistent policy fixtures for CI and local validation.

## What Hooks Cannot Enforce

- They cannot understand every intent behind a command.
- They cannot protect tools or runtimes that do not invoke the hook lifecycle.
- They cannot replace human review for high-risk policy, MCP, credential, or deployment changes.
- They cannot guarantee secrets are absent from every external system or terminal output.

## If a Command Is Blocked

1. Read the block reason and safer alternative printed by the hook.
2. Replace destructive/unsafe command with explicit, reviewable steps.
3. Re-run with minimal privileges and narrower scope.

## Extending Policy

1. Add or adjust a line in `.github/hooks/policy-rules.tsv`.
2. Keep the regex narrow enough to avoid noisy false positives.
3. Provide a specific safer alternative, not just a generic warning.
4. Update both shell variants only when the hook mechanism changes, not when only the rule data changes.
5. Add a denied fixture and at least one safe allowed fixture to `.github/scripts/check-hook-policy.*`.
6. Run `.github/scripts/check-hook-policy.sh` and `.github/scripts/check-hook-policy.ps1` before merging.

## Policy Test Fixtures

Denied fixtures cover destructive deletion, remote shell execution, hard reset, force push, secret writes to `.env`, HTTP package registries, and unapproved policy edits.

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
- Use logs for debugging, policy tuning, and review traceability.
- Never store secrets or raw credentials in hook logs.
