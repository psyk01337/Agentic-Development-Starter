# ADR 0001: Approval-Gated Orchestration Overlay

- Status: Accepted
- Date: 2026-03-09
- Owners: Team
- Related: `.github/starter-modules.json`, `.github/AGENTS.md`, `docs/runbooks/approval-gated-handoffs.md`

## Context

The starter already uses guided handoffs as the baseline operating model and explicitly excludes hidden automatic agent chains from core behavior. At the same time, the starter also anticipates that some teams may later want a more structured handoff process with approval and audit behavior. The repo needed a sanctioned way to support that future need without turning every adopting repo into a workflow engine by default.

## Decision

Add a new default-disabled orchestration overlay module for approval-gated handoffs. This overlay extends the baseline guided handoff contract with transition and approval metadata, but it does not replace the core handoff contract, does not introduce a core runtime orchestration engine, and does not treat approval metadata as enforced authorization. The overlay reuses the existing audit seam conceptually through the current `postToolUse` model and remains opt-in for teams that explicitly choose it.

## Consequences

- Positive outcomes
- Teams now have a sanctioned overlay for approval-gated handoffs without changing the baseline starter.
- The richer transition metadata stays scoped to repos that want it.
- The overlay remains additive and auditable rather than hidden.

- Trade-offs and risks
- The repo now carries another optional module that teams must understand and adopt intentionally.
- Approval metadata may be mistaken for enforcement unless docs remain explicit.
- If a future repo wants true enforcement, it will need a reviewed identity and enforcement model beyond this overlay.

- Operational impacts
- Teams enabling the overlay should update their workflow docs and review their audit expectations.
- Teams not enabling the overlay can continue using guided handoffs unchanged.

## Options Considered

1. Keep orchestration out of the starter entirely

- Pros
- Lowest complexity
- No new overlay to maintain

- Cons
- Leaves teams without a sanctioned pattern for approval-gated transitions

1. Add orchestration into core behavior

- Pros
- Simpler discoverability for teams wanting automation

- Cons
- Violates the baseline design that keeps guided handoffs in core
- Forces orchestration concerns on repos that do not want them

1. Add a default-disabled orchestration overlay

- Pros
- Matches the starter's modular architecture
- Preserves the baseline guided-handoff model
- Allows approval and audit behavior without a core runtime engine

- Cons
- Requires clear docs so teams understand the boundary
- Still leaves future enforcement work for later if needed

## Rollout Plan

1. Add the overlay entry to `.github/starter-modules.json`.
2. Add overlay workflow assets: runbook, skill, and coordinator agent.
3. Update the main agent catalog and runbooks to explain the boundary between core handoffs and overlay metadata.
4. Keep the overlay default-disabled.
5. Revisit only if a repo later needs stronger enforcement or runtime orchestration.

## Validation

Verify that the overlay is listed as an optional, default-disabled module, that the docs explicitly keep guided handoffs as the baseline, and that the richer approval metadata appears only in the overlay assets rather than becoming a new universal core requirement.

## Follow-up

Review date: when a target repo first enables the overlay.

Revisit this ADR if:

- a repo wants true enforcement rather than workflow metadata
- a repo wants background orchestration or scheduling
- the overlay begins to grow beyond lightweight approval-gated transitions
