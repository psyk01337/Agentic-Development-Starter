# Hermes Profile Example

This is a non-executable template for teams that already use a Hermes-style runtime.

## Profile Intent

- Runtime: Hermes-style stateful agent runtime.
- Repo truth: enabled.
- Shell automation: disabled until reviewed.
- MCP servers: disabled until reviewed.
- Durable memory: disabled until reviewed.
- Self-modification of core workflow files: requires explicit approval.

## Required Repo Truth Inputs

- `.github/copilot-instructions.md`
- `.github/starter-modules.json`
- `.github/AGENTS.md`
- `.github/instructions/*.instructions.md`
- `docs/runbooks/memory-strategy.md`
- `docs/runbooks/hermes-runtime.md`

## Approval Gates

- Enable terminal execution.
- Enable MCP servers.
- Enable durable memory.
- Modify `.github/hooks/agent-policy.json` or `.github/hooks/policy-rules.tsv`.
- Modify core instructions or module manifest.

## Validation

- Run starter workflow checks after changing repo workflow assets.
- Confirm MCP and memory remain disabled unless separately approved.