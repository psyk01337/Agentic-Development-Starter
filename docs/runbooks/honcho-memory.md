# Honcho Memory Runbook

Honcho is an optional durable memory and user/project modeling integration. It must not replace repo truth.

## When To Use

Use Honcho when a team has repeated non-sensitive collaboration preferences, long-running project context, or workflow lessons that should survive beyond one session.

Do not use Honcho for secrets, production data, regulated data, or decisions that belong in repo files.

## Default Posture

- Disabled by default.
- Project or repo scoped by default.
- Explicit save behavior.
- Conservative context token cap.
- Conservative dialectic depth.
- Scheduled review and pruning.

## Setup Review

Before enabling Honcho, confirm:

- Memory policy has been reviewed.
- Save scope is repo or directory scoped.
- Secrets and sensitive data are prohibited.
- Repo truth remains authoritative.
- Users know how to inspect, prune, and delete memory.

## Operating Rules

1. Use repo truth for project decisions and standards.
2. Save only stable non-sensitive preferences or repeated patterns.
3. Include retention and pruning guidance for durable memories.
4. Audit memory before sharing across teams or machines.

## Validation

- Review `.github/examples/honcho/honcho.config.example.json` before creating a real local config.
- Run starter validation after adding overlay docs or instructions.
- Confirm no secrets were added to source-controlled examples.