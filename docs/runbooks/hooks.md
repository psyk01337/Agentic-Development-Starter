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
- `git reset --hard`
- `git checkout -- <path>`
- `curl | bash` (or `curl|sh`/`curl|pwsh`)
- Remote content piped to `Invoke-Expression`
- `chmod -R 777`
- Writing likely real secrets/tokens into `.env`
- `pip install --trusted-host` or `pip install --index-url http://` (TLS bypass for package sources)
- `npm install --registry http://` (plain HTTP npm registry)

## If a Command Is Blocked

1. Read the block reason and safer alternative printed by the hook.
2. Replace destructive/unsafe command with explicit, reviewable steps.
3. Re-run with minimal privileges and narrower scope.

## Extending Policy

1. Add or adjust a line in `.github/hooks/policy-rules.tsv`.
2. Keep the regex narrow enough to avoid noisy false positives.
3. Provide a specific safer alternative, not just a generic warning.
4. Update both shell variants only when the hook mechanism changes, not when only the rule data changes.

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
