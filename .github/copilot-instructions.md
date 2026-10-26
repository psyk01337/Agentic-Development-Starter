# Repository Copilot Baseline Instructions

## Scope
These rules are always applied for this repository.

Detailed rules live in instruction files that load by scope:

- `.github/instructions/core.instructions.md` — delivery, definition of done, blast radius, generated code, and check selection.
- `.github/instructions/security.instructions.md` — the always-applied security baseline.
- `.github/instructions/memory.instructions.md` — the memory policy.
- Stack overlays — applied only when a matching file is in context.

Use `.github/starter-modules.json` for the core versus optional inventory, and `docs/runbooks/starter-composition.md` for how instruction files load.

## Non-Negotiable
- Never place secrets, tokens, credentials, or customer data in code, docs, logs, fixtures, or examples.
- Validate untrusted input at boundaries and enforce authorization on protected actions, not authentication alone.
- Read `.github/instructions/security.instructions.md` before touching auth, secrets, file or network access, hooks, MCP, memory, or dependencies.

## Implementation Style
- When asked to implement: give a short plan, then execute it.
- When asked to explain: be direct, brief, and reference concrete files and lines.
- Call out assumptions quickly when context is missing.
- Prefer the generic role and workflow assets first; use stack overlays only when they improve accuracy.
- For complex problems spanning multiple systems or teams with no obvious root cause, invoke the `problem-structuring` skill (`.github/skills/problem-structuring/SKILL.md`) before discovery or implementation.