---
name: refactor-safely
description: Refactor existing behavior without changing observable contracts, using characterization tests, seams, and small reversible steps.
---
# Skill: refactor-safely

## When to Use
Use this skill before restructuring code that already works: extracting modules, splitting functions, moving boundaries, or removing duplication.

## Trigger Examples
- "Split this service class before adding the next feature."
- "Extract this logic so it can be tested."
- "Remove this duplication without changing behavior."
- "Move this package without breaking callers."

## Checklist
- State the behavior that must not change, and the contract that must keep working.
- Find or write characterization tests around the current behavior before editing. If tests are missing, add them first.
- Identify seams: module boundaries, interfaces, dependency injection points, and call sites.
- Prefer a sequence of small, independently valid steps over one wide rename or move.
- Do not change behavior, fix bugs, or reformat unrelated code inside a refactor.
- Keep public contracts and error behavior stable; if they must change, treat it as a separate breaking change.
- Run the focused tests after each step, then the broader suite once at the end.
- Measure the outcome if the stated goal is performance or maintainability, and say how it was measured.

## Safety Boundaries
- Stop and ask before a cross-cutting rename, a large file or package move, or a change to a public API.
- Do not refactor and change behavior in the same commit.
- Do not remove tests that cover behavior you cannot otherwise verify.
- Do not expand the refactor because a better design appeared; record it as a follow-up.

## Output Format (Strict)
1. Invariant
- The behavior and contract that must not change.

2. Seams and plan
- The steps, in order, each independently valid.

3. Characterization evidence
- The tests or checks that pin current behavior.

4. Validation
- Commands run after each step and at the end.

5. Residual risk
- Untested behavior and any contract that remains implicit.

6. Handoff
- Recommended next agent, inputs, decision status, and approvals needed.
