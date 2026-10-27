---
name: session-compaction
description: Preserve task state before a handoff, or compress a long working history into a compact continuation brief before compaction, so the next session can resume without replaying the conversation.
---
# Skill: session-compaction

## When to Use
Use this skill before `/compact`, a long-running handoff, a context reset, or any workflow transition where important session state could be lost. It covers two related jobs: preserving handoff-time state, and compressing accumulated history into a continuation brief.

## Mode 1: Handoff state
Use when the next agent needs the current task state: goal, acceptance criteria, files touched, decisions, validation, and the next action.

1. Separate confirmed facts from inferences and assumptions.
2. Capture the current plan, changed files, validation evidence, and open risks.
3. Drop solved details that no longer affect future decisions.
4. End with the smallest next action.

## Mode 2: Compaction brief
Use when a long working history must be compressed into a compact continuation brief so the next session can resume without replaying the original conversation.

1. Read the accumulated context and separate what must continue from what can go.
2. Build the brief from the ten preserved fields only: current objective, locked decisions, important constraints, relevant architecture, files changed, known failures, verified facts, unresolved questions, current phase, and next actions.
3. Discard conversational filler. Do not restate anything the brief already drops.
4. Never discard unresolved risk or evidence necessary to continue safely.
5. End with the smallest next action.

## Shared Rules
- Keep durable decisions pointed at repo truth such as ADRs, runbooks, or changelogs rather than restating them in session memory.
- Do not treat session memory as a permanent source of truth.
- Do not preserve secrets, credentials, raw logs, customer data, or full command outputs when a short result is enough.
- Stop and ask before preserving regulated or customer-confidential context.

## Output Format
Handoff state:
- Current goal and acceptance criteria
- Files changed or inspected
- Decisions and rationale
- Validation evidence
- Open blockers or risks
- Next recommended action

Compact continuation brief:
- Current objective
- Locked decisions
- Important constraints
- Relevant architecture
- Files changed
- Known failures
- Verified facts
- Unresolved questions
- Current phase
- Next actions

## Boundary
Neither mode is workflow-state storage or a completion declaration. They carry context across a handoff or compaction only; neither updates machine-readable state nor marks any work done.

## Verification Checklist
- The output is short enough to fit in the next session's working context.
- No secrets, raw logs, customer data, or credentials are included.
- Durable decisions point to repo files rather than session memory alone.
- Unresolved risks and evidence necessary to continue safely are still present.
- The next action is specific and executable.

## Referenced Scripts Or Resources
- `docs/runbooks/memory-strategy.md`
- `docs/runbooks/agentic-dev.md`
- `.github/instructions/memory.instructions.md`