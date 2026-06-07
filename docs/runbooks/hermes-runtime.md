# Hermes Runtime Runbook

Hermes-style agents are stateful runtimes. This starter is not trying to become Hermes. It supplies the repo-level operating rules a runtime should consume: instructions, prompts, agents, skills, hooks, policies, memory rules, handoff contracts, and validation checks.

## When To Use

Use the Hermes overlay when a team already has a Hermes-style runtime and wants it to honor repo-native workflow governance.

Do not use this overlay when the repo only needs normal VS Code or Copilot agent guidance.

## Integration Rules

1. Keep Hermes optional and disabled by default.
2. Point the runtime profile at repo truth files before allowing edits.
3. Require explicit approval before enabling shell automation, MCP servers, memory providers, or self-modifying behavior.
4. Apply hook policy rules to terminal and tool execution.
5. Keep transition records aligned with `.github/AGENTS.md` and any enabled approval-gated overlay.

## Runtime Must Not

- Treat runtime state as authoritative over repo files.
- Rewrite core instructions, hooks, or policies without approval.
- Store secrets or sensitive data in memory.
- Enable external tools by default.

## Verification

- Confirm the profile references `.github/copilot-instructions.md` and `.github/starter-modules.json`.
- Confirm high-risk tools require approval.
- Confirm memory follows `docs/runbooks/memory-strategy.md`.
- Run `.github/scripts/check-starter-workflow.sh` or `.github/scripts/check-starter-workflow.ps1` after overlay changes.