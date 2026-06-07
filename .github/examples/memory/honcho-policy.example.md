# Honcho Memory Policy Example

This example is documentation only. Do not treat it as an enabled Honcho configuration.

## Default Scope

- `scope`: repo
- `sessionStrategy`: per-repo
- `saveBehavior`: explicit
- `contextTokenCap`: 8000
- `dialecticDepth`: conservative

## Allowed Memory

- Stable team preferences for review style, changelog use, and validation habits.
- Repeated workflow lessons that do not contain private data.
- Long-running non-sensitive project context.

## Prohibited Memory

- Secrets, tokens, credentials, passwords, private keys, and certificates.
- Customer private data, raw logs, production credentials, or regulated data.
- Durable decisions that should be stored in repo truth.

## Review Cadence

- Review saved memory at milestone boundaries.
- Prune stale, incorrect, or over-broad memories.
- Move durable project facts into repo files.