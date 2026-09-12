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
