---
applyTo: "**/*"
---
# Honcho Memory Overlay Instructions

Use these rules only when a repository explicitly opts into Honcho or another durable agent memory provider. Honcho is optional and must not become the source of truth.

## Memory Boundaries

- Repo files remain authoritative for decisions, policies, contracts, runbooks, and changelogs.
- Follow the three-layer memory model in `.github/instructions/memory.instructions.md`: session memory for task state, repo truth for durable facts, optional durable memory for stable non-sensitive preferences.
- Default to project or repo scoped memory, not global memory.
- Keep save behavior explicit and reviewable.
- Use conservative context caps and pruning rules.

## Allowed Durable Memory

- Stable user or team preferences.
- Long-running non-sensitive project context.
- Repeated workflow patterns and lessons learned.
- Collaboration preferences that do not encode private or regulated data.

## Prohibited Durable Memory

- Secrets, API keys, tokens, passwords, credentials, private keys, or certificates.
- Customer private data, regulated data, production logs, sensitive incident details, or legal/medical/financial private information.
- Any policy or project fact that should live in repo truth.

## Verification

- Review saved memories periodically.
- Prune stale or incorrect memory.
- Confirm sensitive data is absent before enabling sync or shared scopes.