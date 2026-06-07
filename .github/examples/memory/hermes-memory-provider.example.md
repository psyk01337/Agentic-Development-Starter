# Hermes Memory Provider Example

This example describes an optional memory provider contract for a Hermes-style runtime. It is not enabled by default.

## Provider Contract

- Read `.github/instructions/memory.instructions.md` before saving memory.
- Store session memory separately from durable memory.
- Keep durable memory repo scoped unless the user approves broader scope.
- Provide inspect, prune, and delete operations.

## Save Rules

- Save only explicit user-approved or agent-proposed memories.
- Redact secrets and sensitive data before any persistence.
- Link durable decisions back to repo truth files.

## Runtime Checks

- Reject secret-like values.
- Reject raw production logs and customer private data.
- Record memory scope and retention intent.