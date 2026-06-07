---
name: session-compaction
description: Preserve task state before context compaction or handoff so agents can resume without re-deriving decisions.
---
# Skill: session-compaction

## When to Use
Use this skill before `/compact`, long-running handoff, context reset, or any workflow transition where important session state could be lost.

## Inputs Expected
- Current goal and acceptance criteria.
- Files changed or inspected.
- Decisions made and rejected options.
- Validation run and outstanding failures.
- Blockers, approvals, and recommended next agent.

## Procedure
1. Separate confirmed facts from inferences and assumptions.
2. Capture the current plan, changed files, validation evidence, and open risks.
3. Keep durable decisions pointed at repo truth such as ADRs, runbooks, or changelogs.
4. Drop solved details that no longer affect future decisions.
5. End with the smallest next action.

## Output Format
- Current goal
- Acceptance criteria
- Files changed or inspected
- Decisions and rationale
- Validation evidence
- Open blockers or risks
- Next recommended action

## Verification Checklist
- The summary is short enough to fit in the next agent's working context.
- No secrets, raw logs, customer data, or credentials are included.
- Durable decisions point to repo files rather than session memory alone.
- The next action is specific and executable.

## Safety Notes
- Do not treat session memory as permanent source of truth.
- Do not preserve sensitive data or full command outputs when a short result is enough.
- Stop and ask before preserving regulated or customer-confidential context.

## Referenced Scripts Or Resources
- `docs/runbooks/memory-strategy.md`
- `docs/runbooks/agentic-dev.md`
- `.github/instructions/memory.instructions.md`