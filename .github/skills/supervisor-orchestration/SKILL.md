---
name: supervisor-orchestration
description: Optional overlay skill for running supervised delegation of bounded tasks to approved specialist agents while keeping guided handoffs as the core default.
---
# Skill: supervisor-orchestration

## When to Use
Use this skill when a repo has explicitly enabled `overlay-supervisor-orchestration` and a task should be classified, delegated to approved specialist agents, reconciled, and reported as one coherent outcome.

Do not use it for human-guided transitions between agents; that is the `approval-gated-handoffs` skill and the `orchestration-coordinator` role.

## Trigger Examples
- "Run this feature through supervised delegation and reconcile the results."
- "Classify this task, then delegate it to the right specialists under the supervisor overlay."
- "Execute the complex branch of the supervisor workflow with a declared write set."

## Canonical Sources
- `.github/roles/orchestration-policy.json` for approval categories, routing criteria, the specialist allow-list, delegation depth, and the write-set rule.
- `.github/roles/tool-access.json` for each agent's capability boundary.
- `.github/AGENTS.md` for the guided handoff contract and ownership map.
- `docs/runbooks/supervisor-orchestration.md` for the operating model and fallback behavior.
- `docs/runbooks/engineering-team.md` for the team topology, task board, task assignment contract, and SDLC ceremonies.
- `.github/skills/repair-loop/SKILL.md` and `docs/runbooks/agentic-engine.md` for the deterministic implement-verify-repair loop.

## Checklist
- Confirm the repo has enabled the supervisor orchestration overlay.
- Classify the task as `simple` or `complex` using the routing criteria; default to `complex` when uncertain.
- Check the proposed work against the approval-required categories and obtain explicit human approval before crossing a matching boundary.
- Confirm every target agent is on the specialist allow-list.
- Confirm only one delegation level is used and no worker is asked to delegate.
- Declare the write set before any write-capable delegation; serialize when it is unknown or unbounded.
- Run parallel delegations only for read-only analysis or review, or for provably disjoint declared write sets.
- Reconcile results, consolidate blocking findings into one repair task, and re-run the affected verification once.
- Keep a reviewer from approving work it implemented itself.
- For multi-stage work, build a task board and assign approved specialists by squad using `docs/runbooks/engineering-team.md`.
- Run write work through the `agentic_engine.py` loop so repairs are bounded and completion requires evidence.

## Repair Loop

Use `repair-loop` and `agentic_engine.py` for any task that may need more than one fix attempt:

- Initialize a task-scoped run with acceptance criteria and a declared write set.
- Record `implement`, `verify`, `repair`, and `review` results through the engine.
- Let the engine stop the loop on `VERIFIED`, an identical failure signature, an exhausted attempt budget, or `INCONCLUSIVE`.
- Escalate the blocker packet instead of retrying manually.
- Never raise `maxRepairAttempts` to force a pass.

## Team Management

When the task spans multiple SDLC stages or squads, use `docs/runbooks/engineering-team.md`:

- Build a task board with objective, owner, reviewer, acceptance criteria, write set, dependencies, evidence, and status.
- Assign approved specialists by squad and keep exactly one delegation level.
- Run read-only analysis and review in parallel; serialize or isolate writes.
- Use `swarm` for independent slices and `arena-bakeoff` for design alternatives.
- Mark `DONE` only after verification evidence; `INCONCLUSIVE` is never success.

## Fallback
If the runtime cannot delegate subagents, produce a guided delegation plan instead of implying delegation occurred. Each entry states the target agent, objective, context, write set where applicable, acceptance criteria, expected return format, and execution order.

## Output Format (Strict)
Produce sections in this exact order:

1. Classification
- `simple` or `complex`, with the routing criterion that decided it.

2. Approval Check
- Categories matched from `.github/roles/orchestration-policy.json`, approval status, and the fallback if approval is withheld.

3. Delegations
- One entry per delegation: target agent, objective, declared write set, and whether it ran in parallel or serialized.

4. Reconciliation
- Consolidated result, conflicts found between agent outputs, and how each was resolved.

5. Verification
- Independent verification outcome, blocking findings, and the repair pass if one occurred.

6. Handoff
- Recommended next agent, inputs for that agent, decision status, and blockers or approvals needed.

## Risks
- Prompt-level gating can be ignored; documentation must not present it as enforced authorization.
- A misdeclared write set can still cause concurrent edits to overlap.
- Over-delegation adds cost and latency without adding safety.
