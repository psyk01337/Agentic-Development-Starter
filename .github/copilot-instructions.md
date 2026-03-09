# Repository Copilot Baseline Instructions

## Scope
These rules are always applied for this repository.

This starter is modular. Treat `.github/instructions/core.instructions.md` and `.github/instructions/security.instructions.md` as the default baseline, and apply stack-specific overlays only when the target repo actually uses that stack.

Use `.github/starter-modules.json` to understand which instructions, skills, agents, and templates are core versus optional.

## Delivery Rules
- Keep diffs small, focused, and easy to review.
- If behavior changes, update tests and update docs in the same change.
- Reuse existing patterns before introducing new abstractions.
- Respect current architecture boundaries and naming conventions.
- Ask before doing broad refactors, cross-cutting renames, or large file moves.
- Do not assume a language, framework, test runner, or deployment model that is not established by the current repo.

## Security Rules
- Never add secrets, tokens, or credentials to code, docs, logs, fixtures, or examples.
- Use environment variables for sensitive values and document required variables.
- Validate and sanitize untrusted input at boundaries.
- Enforce authorization checks, not only authentication checks.
- Keep logs safe: no secrets, no raw tokens, no sensitive payload dumps.

## Implementation Style
- When asked to implement: provide a short plan, then execute it.
- When asked to explain: be direct, brief, and reference concrete files/lines.
- Call out assumptions quickly when context is missing.
- Prefer generic instructions, roles, and runbooks first; use optional stack overlays only when they improve accuracy.
