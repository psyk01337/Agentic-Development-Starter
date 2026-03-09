---
name: qa-test-plan
description: Produce a lightweight QA test plan focused on risky flows, coverage gaps, and the smallest useful validation set.
---
# Skill: qa-test-plan

## When to Use
Use this skill when a change needs a focused QA plan before or after implementation, especially when the risky user flows or failure modes need to be made explicit.

## Trigger Examples
- "Create a QA plan for this feature."
- "List the risky flows and minimum validation for this change."
- "What should QA verify before we ship this?"

## Checklist
- Identify the main user flows and the highest-risk failure cases.
- Distinguish happy-path checks from edge-case and regression checks.
- Point out missing coverage, weak assumptions, and required environments or fixtures.
- Keep the test plan minimal but sufficient for release confidence.
- Prefer explicit pass/fail criteria over vague guidance.

## Output Format (Strict)
Produce sections in this exact order:
1. Scope
- What feature, flow, or change the plan covers.
2. Critical Flows
- The highest-priority user journeys to verify.
3. Failure Cases
- Important unhappy paths and regression risks.
4. Minimum Validation Set
- The smallest set of checks that should run before signoff.
5. Coverage Gaps
- What is still unverified or weakly tested.