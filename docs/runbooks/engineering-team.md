# Engineering Team Runbook

Use this runbook when a project or feature should run like a small software engineering department: discovery, design, implementation, review, QA, security, documentation, release, and retrospective.

## Operating Model

`delegation-supervisor` is the engineering manager and tech lead. It owns the task board, assigns bounded work to approved specialists, reconciles results, and declares completion only after verification evidence.

This runbook assumes `overlay-supervisor-orchestration` is enabled. If it is disabled, use the guided handoff chains in `docs/runbooks/agentic-dev.md` instead.

v1 uses exactly one delegation level. Specialists do not delegate. A nested team-lead model would require a separate ADR, policy change, validator updates, and security review.

## Team Topology

| Squad | Agents | Owns |
| --- | --- | --- |
| Discovery | `analyst`, `tech-planner` | Requirements, research, options, design, ADR |
| Architecture | `architecture-reviewer` | Boundaries, contracts, architecture fit |
| Implementation | `senior-software-engineer`, `tdd-vitest` | Code, tests, focused delivery |
| Quality and Security | `code-reviewer`, `qa`, `security-reviewer` | Review, verification, security |
| Delivery | `documentation-maintainer`, `process-improvement` | Docs, changelogs, release notes, retro |
| Management | `delegation-supervisor` | Task board, routing, delegation, reconciliation |
| Approval | `orchestration-coordinator` | Human-approved transitions, when the overlay is enabled |

Cross-cutting skills: `problem-structuring`, `adr-authoring`, `qa-test-plan`, `pr-review`, `security-check`, `release-notes`, `decision-trail`, `verification-evidence-loop`, `repair-loop`, `adversarial-review`, `arena-bakeoff`, `swarm`, `prose-cleanup`, and `session-compactor`.

## SDLC Stages

1. **Intake and discovery** — classify the request, confirm acceptance criteria, and collect evidence.
2. **Requirements** — write or update the PRD or specification; identify non-goals and open questions.
3. **Design and architecture** — options, tradeoffs, ADR, boundaries, and data flow.
4. **Plan and breakdown** — work breakdown, dependencies, write sets, owners, and required evidence.
5. **Implementation** — deliver the smallest vertical slice and add tests with the change.
6. **Review** — code review, plus security review when the change touches auth, secrets, hooks, MCP, memory, dependencies, or command execution.
7. **Verification** — QA runs the smallest real check; `verification-evidence-loop` records `VERIFIED`, `NOT_VERIFIED`, or `INCONCLUSIVE`.
8. **Documentation and release** — changelogs, runbooks, release notes, and a PR-ready summary.
9. **Retro** — process-improvement records friction and proposes one bounded improvement when real friction appears.

## Task Assignment Contract

Every assignment states:

- Task ID and parent objective
- Owner and reviewer
- Scope and out-of-scope
- Acceptance criteria
- Declared write set
- Dependencies and parallel safety
- Required evidence
- Stop conditions
- Return format shaped by `delegation-result.schema.json`
- Approval category, if any

A task without acceptance criteria or a bounded write set is not ready for implementation.

## Task Board

Statuses: `PLANNED`, `READY`, `IN_PROGRESS`, `BLOCKED`, `IN_REVIEW`, `VERIFYING`, `DONE`, `DEFERRED`.

Only the supervisor may mark `DONE`, and only after verification evidence satisfies the success predicate. `INCONCLUSIVE` is never success. Keep the board in session or task-scoped state; do not commit a global workflow-state file.

## Bounded Repair Loop

Use the `repair-loop` skill and `.github/scripts/agentic_engine.py` for any task that may need more than one fix attempt:

```text
init -> implement -> verify -> (VERIFIED -> review -> done)
                          \-> (NOT_VERIFIED -> repair -> verify)
                          \-> (identical failure or budget -> blocked)
```

The engine enforces:

- task-scoped state under `.agentic/state/<run-id>.json`
- a declared write set; changes outside it are blocked
- evidence required at every stage
- `maxRepairAttempts` and `maxVerifyRetries` from `retryPolicy`
- a failure signature that stops repeated identical failures
- approval categories before implementation
- `INCONCLUSIVE` never completing

See `docs/runbooks/agentic-engine.md` for commands and result shapes.

## Parallel Work

- Read-only analysis and review may run in parallel.
- Write tasks run in parallel only with disjoint declared write sets.
- Serialize unknown, broad, wildcard-only, or overlapping write sets.
- Use `swarm` for independent slices and `arena-bakeoff` for competing designs.
- Aggregate only after all required slices finish.

## Ceremonies

- **Kickoff** — classify, confirm acceptance criteria, and build the board.
- **Design review** — tech-planner presents options; architecture-reviewer gives a fit verdict.
- **Implementation** — senior-software-engineer or tdd-vitest delivers one slice.
- **Review** — code-reviewer and, when needed, security-reviewer.
- **Verification** — qa runs the real check and records evidence.
- **Release** — documentation-maintainer updates docs and changelogs; prepare the PR summary.
- **Retro** — process-improvement records friction and proposes one bounded improvement.

## Escalation

Stop and surface when:

- Acceptance criteria are missing or contradictory.
- Scope expands beyond the declared slice or write set.
- The task crosses an approval category in `.github/roles/orchestration-policy.json`.
- Two agents produce conflicting results that cannot be reconciled.
- Validation cannot run or returns `INCONCLUSIVE`.
- The work would require nested delegation, which v1 does not support.

## Output

- Team plan and task board
- Assignments with declared write sets
- Status, blockers, and approvals
- Verification evidence and verdict
- Consolidated result
- Next action and residual risk
