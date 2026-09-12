# Fix Bug

Use this prompt to fix a defect with a falsifiable hypothesis, the smallest fix, and a regression test.

## Context To Inspect First

- `.github/copilot-instructions.md` and any instruction overlays that match the touched files.
- The bug report or failing symptom, nearby tests, and recent changelog entries for related behavior.
- The `bug-triage` skill at `.github/skills/bug-triage/SKILL.md` when symptoms are still ambiguous.

## Deliverables

- One falsifiable local hypothesis and one cheap check to confirm or refute it.
- The smallest code change that fixes the root cause, not just the symptom.
- A regression test that fails before the fix and passes after it.
- Changelog updates following the repo's split-log rules.

## Safety Boundaries

- Do not fix symptoms only; state why the root cause is addressed.
- Do not disable or skip failing tests.
- Do not expand scope into unrelated refactors.
- Stop and ask before destructive changes.

## Expected Output

- Root cause summary
- Files changed
- Regression test added
- Validation run
- Residual risks
- Recommended next review step
