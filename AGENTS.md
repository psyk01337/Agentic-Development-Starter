# Project Instructions

This repository is the Agentic Development Starter: a modular workflow and governance layer for AI-assisted delivery. Detail lives in scoped files; this page is the cross-agent entry point that AGENTS.md-aware harnesses read.

## Read Before Changing Anything

- `.github/instructions/core.instructions.md` — delivery rules, definition of done, blast radius, and how to choose a check.
- `.github/instructions/security.instructions.md` — the security baseline; read it before touching auth, secrets, file or network access, hooks, MCP, memory, or dependencies.
- `.github/instructions/memory.instructions.md` — session memory, repo truth, and durable memory.
- Overlays under `.github/instructions/` — apply one only when the repo actually uses that stack.

`.github/copilot-instructions.md` holds the Copilot-specific baseline and is not repeated here.

## Non-Negotiable

- Never place secrets, tokens, credentials, or customer data in code, docs, logs, fixtures, or examples.
- Validate untrusted input at boundaries; enforce authorization, not authentication alone.
- Report validation as commands and results, never as a claim.
- Keep diffs small, focused, and inside the agreed scope.

## Where To Go Next

- `QUICKSTART.md` — fastest path to a first change.
- `.github/AGENTS.md` — agent catalog, guided handoff contract, and delegation triggers.
- `docs/runbooks/INDEX.md` — guidance by task.
- `.github/starter-modules.json` — what ships enabled.
