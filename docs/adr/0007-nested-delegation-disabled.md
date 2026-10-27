# ADR 0007: Nested Delegation Remains Disabled

- Status: Proposed
- Date: 2026-10-27
- Owners: Team
- Related: `docs/adr/0003-supervisor-orchestration-overlay.md`, `docs/adr/0004-adapter-bound-delegation.md`, `.github/roles/orchestration-policy.json`, `.github/scripts/check-supervisor-orchestration.sh`, `docs/runbooks/supervisor-orchestration.md`, `docs/runbooks/agentic-engine.md`, `.github/scripts/agentic_engine.py`

## Context

`delegationDepth` in `.github/roles/orchestration-policy.json` records `maxLevels: 1` and `nestedDelegationEnabled: false`. That limit is not a platform ceiling. The VS Code subagents guide documents `chat.subagents.allowInvocationsFromSubagents`, which enables subagents to invoke further subagents to a maximum depth of five, and the supervisor already delegates through the host adapter map. The repository constraint is therefore a deliberate policy choice that nothing prevents from being lifted.

The choice matters because the two obvious futures look identical in the happy path and differ sharply in failure behaviour. A well-behaved recursion resolves quickly; a misbehaving one multiplies cost, duplicates work, and can loop without ever tripping a bound.

Constraints that frame the decision:

- The supervisor is the only agent holding `delegate-agent`, and that sole-holder invariant is enforced in both validator twins.
- Delegated subagents are stateless: no inherited history, no clarifying questions, no todo tools. A nested worker therefore receives only what its parent passes down, and each hop loses fidelity.
- The agentic engine enforces `retryPolicy` per task run (`maxRepairAttempts: 3`, `identicalFailureThreshold: 2`, `maxWallClockMinutes: 120`) at a single level. It has no concept of a parent run owning child runs.
- Authorization is a prompt-level contract, not an enforced capability boundary. Depth makes that gap wider: a second-level delegation is one more hop no validator can see.

## Decision

Nested delegation stays disabled. `maxLevels` remains `1`, `nestedDelegationEnabled` remains `false`, and the supervisor continues to refuse any request that would create a second delegation level.

Two conditions must both hold before this ADR is revisited. First, a real task must exist that cannot be decomposed at one level without a worker delegating on. Second, that task must demonstrate a concrete need for the capability rather than a preference for tidier role names.

## Consequences

- Positive: one delegation level keeps the cost and reasoning bound obvious, keeps the sole-holder invariant checkable by a stateless validator, and keeps every delegated task's input fully described by its parent payload.
- Positive: no change to policy, validators, fixtures, or the runbook, so the current suite stays green and the ADR costs nothing to adopt.
- Trade-off: team-lead-shaped work (an analyst who spawns researchers, a planner who spawns planners per subsystem) must be serialized at the supervisor level. That is more supervisor turns and more context in the parent, not more depth.
- Trade-off: the limit is a policy claim, not a technical one. A host adapter could permit nesting while the repository says it is disabled, so the setting is only as strong as the runbook instruction and reviewer discipline.
- Risk: when the limit is finally lifted, the existing validator cannot detect a second level, so the invariant would need a new mechanism before the policy change ships.

## Options Considered

1. Keep depth at 1 (chosen)

- Pros: smallest blast radius, no validator redesign, no budget semantics to invent, and the current suite proves the bound.
- Cons: caps team-shaped decomposition at one level, and pushes coordination cost into the supervisor's context.

1. Raise `maxLevels` without changing the engine

- Pros: minimal policy edit; the host already supports depth five.
- Cons: creates runs the engine cannot account for. A child run would consume wall clock and attempts that no parent budget observes, so `maxWallClockMinutes` and `maxRepairAttempts` would silently stop bounding total work. The sole-holder validator has no vocabulary for a second-level holder.

1. Full recursive model: child runs with budgets, depth in state, and per-depth evidence

- Pros: the only version that is actually safe, with each child run budgeted, depth recorded in state, and aggregation defined.
- Cons: touches `agentic_engine.py` state schema, `retryPolicy`, both validator twins, the fixtures, the runbook, and the supervisor agent. This is a multi-slice change needing its own design pass, and it should not be attempted as an incidental edit.

## Rollout Plan

No implementation is authorized by this ADR. It records the current decision and the conditions for revisiting it.

If the decision is reversed later, the minimum safe sequence is: add depth and parent-run references to engine state, derive child budgets from the parent's remaining allowance, extend the validator to reject a declared depth above the policy limit, add fixtures for a permitted second level and a rejected third level, then raise `maxLevels` in the policy.

## Validation

The current decision is already observable:

- `python .github/scripts/agentic_engine.py selftest` covers the bounded retry loop at one level.
- Both `check-supervisor-orchestration` twins reject a second agent declaring `delegate-agent`, and reject an agent allow-list on any non-supervisor agent.
- `.github/scripts/check-agentic-engine.sh` and `.ps1` validate `retryPolicy` shape and run the engine self-tests.

A reversal must show these checks still pass and add the missing depth assertions before the policy value changes.

## Follow-up

Review when a real task cannot be decomposed without a second level, or when the host's nested-subagent default changes in a way that makes nesting the common path. Revisit owner: whoever next changes `delegationDepth`.

If the answer is still "serialize it", update this ADR's status to `Rejected` rather than leaving it `Proposed` indefinitely.
