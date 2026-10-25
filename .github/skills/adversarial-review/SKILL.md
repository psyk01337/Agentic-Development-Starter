---
name: adversarial-review
description: Optional overlay skill for adversarial interrogation of a change, used with the supervisor orchestration overlay; attempts to prove the implementation wrong across thirteen review lenses and returns deduplicated, evidence-first findings.
---
# Skill: adversarial-review

## When to Use
Use when the repo has enabled `overlay-supervisor-orchestration` and a completed implementation slice must be interrogated before the orchestrator can rely on it. This is not stylistic review: the purpose is to attempt to prove the implementation is wrong.

Use independent reviewers when the host supports them; each reviewer takes its own lens pass over the same change.

## Inputs
Reviewers must inspect the actual diff and the relevant surrounding implementation — not summaries and not agent self-reports.

## Review Lenses
Cover every lens that applies to the change, and name which lenses were skipped and why:

- correctness
- hidden assumptions
- boundary conditions
- concurrency
- failure handling
- security
- authorization
- data integrity
- compatibility
- maintainability
- test weakness
- silent fallback behavior
- unnecessary complexity

## Finding Format (Strict)
Every finding records these six fields, in this order: SEVERITY, LOCATION, CLAIM, EVIDENCE, FAILURE_SCENARIO, RECOMMENDED_ACTION.

- `SEVERITY`: `blocker`, `major`, `minor`, or `note`.
- `LOCATION`: file and line range, or symbol.
- `CLAIM`: what the reviewer asserts is wrong.
- `EVIDENCE`: the observable artifact or code path that supports the claim.
- `FAILURE_SCENARIO`: the concrete situation where the defect produces a wrong outcome.
- `RECOMMENDED_ACTION`: the smallest correction, or the evidence that would refute the claim.

A finding without `EVIDENCE` and a `FAILURE_SCENARIO` is not a finding; record it as an open question instead.

## Synthesis
One synthesizer merges the reviewers' output:

- Deduplicate findings: the synthesizer must deduplicate findings that describe the same defect and merge their evidence.
- Evidence outranks voting: do not implement issues solely because multiple agents repeated the same unsupported claim.
- Escalate unsupported but credible concerns as open questions, not as findings.

## Output Format (Strict)
1. Verdict: exactly one of `BLOCKED` (at least one blocker with evidence), `CHANGES_REQUIRED` (no blocker, at least one major), `PASS_WITH_NOTES`, or `CLEAN`.
2. Findings: the deduplicated list, each with the six fields in the fixed order.
3. Open Questions: unsupported or unverified concerns that need evidence before they become findings.
4. Residual Risk: what the review did not cover, and which lenses were skipped and why.
