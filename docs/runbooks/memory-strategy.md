# Memory Strategy Runbook

This starter uses memory as a workflow aid, not as an authority. Repo files remain the durable source of truth.

## Layer 1: Session And Handoff Memory

Use session memory for the current task only:

- Current plan and acceptance criteria.
- Open blockers and approval status.
- Files changed or inspected.
- Tests and validation run.
- Next recommended step and next agent.

Do not use session memory for permanent project decisions, secrets, customer confidential information, or raw production logs.

## Layer 2: Repo Truth

Use repo files for durable shared facts:

- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `.github/AGENTS.md`
- `.github/skills/*/SKILL.md`
- `docs/adr/*.md`
- `docs/runbooks/*.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`

Repo truth owns architecture decisions, coding standards, API contracts, security policy, testing strategy, runbooks, dependency decisions, migration decisions, and changelog history.

## Layer 3: Optional Durable Agent Memory

Use optional providers such as Honcho only after review. Durable agent memory may store stable non-sensitive preferences, repeated workflow patterns, long-running project context, and lessons learned across sessions.

Never store secrets, API keys, passwords, customer private data, sensitive logs, production credentials, legal private information, medical private information, financial private information, or regulated data unless explicitly approved and documented.

## Honcho Policy Defaults

- Default to project or repo scoped memory.
- Prefer `sessionStrategy: per-repo` or `sessionStrategy: per-directory`.
- Set a context token cap.
- Keep dialectic depth conservative.
- Make save behavior explicit.
- Review and prune memory regularly.

## Memory Audit Checklist

- Is this fact already better stored in repo truth?
- Is the memory scoped to the smallest useful repo, directory, team, or user context?
- Does it avoid secrets, credentials, customer data, and regulated data?
- Is there a review or pruning path?
- Can a future agent understand when this memory should no longer apply?

## Handoff Checklist

Before handoff, preserve:

- What changed or was learned.
- Current status and decision state.
- Validation evidence.
- Open blockers and approvals needed.
- The smallest useful next action.