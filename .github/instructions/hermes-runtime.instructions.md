---
applyTo: "**/*"
---
# Hermes Runtime Overlay Instructions

Use these rules only when a repository explicitly opts into a Hermes-style stateful runtime. This starter is not a Hermes replacement; it supplies repo-native rules, skills, prompts, policies, and handoff contracts for runtimes to honor.

## Runtime Boundaries

- Read repo truth before acting: `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `.github/AGENTS.md`, `.github/starter-modules.json`, runbooks, ADRs, and changelogs.
- Treat Hermes state as execution context, not source of truth.
- Do not self-modify core instructions, hooks, policies, or module manifests without explicit user approval.
- Keep MCP, shell automation, and memory providers disabled until reviewed.

## Safety Expectations

- Honor hook policy rules even if the runtime has its own tool controls.
- Use repo handoff contracts for transitions and preserve approval status when orchestration overlays are enabled.
- Keep optional memory use within `.github/instructions/memory.instructions.md`.
- Log validation evidence without secrets, raw tokens, or private customer data.

## Verification

- Confirm enabled Hermes profiles point to repo truth files.
- Confirm dangerous tools require approval.
- Confirm runtime memory is scoped and reviewable.