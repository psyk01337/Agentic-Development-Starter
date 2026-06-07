---
applyTo: "**/*"
---
# Memory Instructions

Use memory deliberately and keep repo files authoritative.

## Three-Layer Model

1. Session and handoff memory is for the current task plan, acceptance criteria, open blockers, files changed, tests run, and next recommended step.
2. Repo truth is for durable project facts: instructions, agents, skills, ADRs, runbooks, changelogs, API contracts, security policy, dependency decisions, and migration decisions.
3. Optional durable agent memory is for stable non-sensitive user or team preferences, repeated workflow patterns, and long-running project context.

## Storage Rules

- Prefer repo truth for durable facts that future teammates or agents must share.
- Keep session memory short, current, and disposable.
- Keep optional durable memory scoped to the repo or directory unless a user explicitly approves broader scope.
- Store memory explicitly; do not silently persist sensitive context.

## Never Store

- Secrets, API keys, passwords, private keys, tokens, credentials, or signing material.
- Customer private data, raw production logs, sensitive incident payloads, or regulated data.
- Legal, medical, financial, or employment-private information unless explicitly approved and documented.
- Anything that should be enforced by repo files instead of remembered by an agent.

## Verification

- Before saving memory, classify the layer and sensitivity.
- Before handoff, summarize only the fields needed by the next agent.
- When a memory describes a durable decision, update the relevant repo truth file instead.