---
name: session-compactor
description: Transforms accumulated engineering context into a compact continuation brief before compaction; unlike session-compaction, which preserves handoff-time state, this compacts a long working history into the ten-field brief.
---
# Skill: session-compactor

## When to Use
Use this skill when a long working history must be compressed before compaction, context reset, or resumption: the accumulated engineering context is rewritten as a compact continuation brief that the next session can resume from without replaying the original conversation.

## Inputs Expected
- The accumulated session: task history, decisions, constraints, files touched, failures, verification results, open questions, and the current workflow phase.

## Procedure
1. Read the accumulated context and separate what must continue from what can go.
2. Build the brief from the ten preserved fields only:
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
3. Discard conversational filler. Do not restate anything the brief already drops.
4. Never discard unresolved risk or evidence necessary to continue safely.
5. Point durable decisions at repo truth such as ADRs, runbooks, or changelogs rather than restating them in the brief.
6. End with the smallest next action.

## Output Format
The compact continuation brief:
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
The compact continuation brief is not workflow-state storage and is not a completion declaration. It carries context across a compaction only; it neither updates machine-readable state nor marks any work done.

## Safety Notes
- Do not include secrets, credentials, raw logs, or customer data in the brief.
- Do not treat the brief as a permanent source of truth; durable decisions must point to repo truth, not session memory alone.
- Stop and ask before preserving regulated or customer-confidential context.

## Division of Labor with `session-compaction`
Use the core `session-compaction` skill when state must survive a handoff or compaction at handoff time: it preserves the current plan, acceptance criteria, validation evidence, and next recommended action. Use this `session-compactor` skill when a long working history must be compressed into a compact continuation brief: it compacts the accumulated history into the ten-field brief and discards conversational filler. The two skills serve different purposes: `session-compaction` captures handoff-time state, and `session-compactor` compresses a long working history into the compact continuation brief; their trigger conditions can overlap, and choosing between them follows the state-versus-history split above.

## Verification Checklist
- Only the ten preserved fields remain; conversational filler is gone.
- The brief is short enough to fit in the next session's working context.
- No secrets, raw logs, customer data, or credentials are included.
- Durable decisions point to repo files rather than session memory alone.
- Unresolved risks and evidence necessary to continue safely are still present.
- The next action is specific and executable.

## Referenced Scripts Or Resources
- `.github/skills/session-compaction/SKILL.md`
- `docs/runbooks/memory-strategy.md`
- `.github/instructions/memory.instructions.md`
