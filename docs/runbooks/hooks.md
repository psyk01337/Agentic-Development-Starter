# Hooks Runbook

## Purpose

Hooks enforce deterministic guardrails and create an audit trail for agent tool usage.

## Files

- Policy: `.github/hooks/agent-policy.json`
- Session start: `.github/hooks/scripts/session-banner.ps1`
- Pre-tool policy: `.github/hooks/scripts/pre-tool-policy.ps1`
- Post-tool audit: `.github/hooks/scripts/audit-log.ps1`
- Optional WSL scripts: `.github/hooks/scripts/*.sh`

## Lifecycle

1. `sessionStart`: prints banner and logs session metadata.
2. `preToolUse`: inspects pending tool action/command and blocks dangerous patterns.
3. `postToolUse`: appends timestamped audit records.

## Blocked Patterns (Examples)

- `rm -rf`
- `del /s /q`
- `curl | bash` (or `curl|sh`)
- Remote content piped to `Invoke-Expression`
- Writing likely real secrets/tokens into `.env`

## If a Command Is Blocked

1. Read the block reason and safer alternative printed by the hook.
2. Replace destructive/unsafe command with explicit, reviewable steps.
3. Re-run with minimal privileges and narrower scope.

## Audit Log Usage

- Logs are written to `.github/hooks/logs/agent-audit.log` as JSON lines.
- Use logs for debugging, policy tuning, and review traceability.
- Never store secrets or raw credentials in hook logs.
