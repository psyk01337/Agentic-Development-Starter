---
name: pr-review
description: Perform a practical pull request review focused on correctness, risk, and maintainability.
---
# Skill: pr-review

## When to Use
Use this skill when reviewing feature, bugfix, or refactor changes before merge.

## Trigger Examples
- "Review this PR for correctness and regressions."
- "Do a code review and call out risks."
- "Check this diff before I merge."

## Checklist
- Correctness: behavior matches requirements and changed code paths are coherent.
- Edge cases: null/empty/error states, boundary values, retries/timeouts handled.
- Tests: sufficient unit/integration/e2e coverage for changed behavior.
- Security: input validation, authz checks, secret-safe logging, no risky command usage.
- Performance: no obvious N+1, redundant renders, expensive hot-path work.
- DX: readability, naming, maintainability, and docs/changelog impact.

## Output Format (Strict)
Produce sections in this exact order:
1. Summary
- Bullet 1
- Bullet 2
- Bullet 3
2. Risks
- `[High|Medium|Low]` risk statement with file reference.
3. Suggestions
- Actionable, smallest-safe changes first.
4. Quick Patch (optional)
- Minimal patch snippet only if a fix is obvious and low-risk.
