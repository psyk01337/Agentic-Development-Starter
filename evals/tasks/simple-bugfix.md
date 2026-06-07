# Golden Task: Simple Bugfix

## Scenario

A small, localized behavior is failing. The agent must inspect nearby code and tests, implement the smallest fix, update or add a test, and validate the touched slice.

## Instructions To Agent

1. Read the repo baseline instructions first.
2. Locate the failing behavior from the provided symptom.
3. Form one local hypothesis and one cheap check.
4. Make the smallest code change that fixes the behavior.
5. Update the nearest test and changelog if behavior changes.
6. Run the smallest relevant validation command.
7. Produce a handoff with files changed, validation, and residual risk.

## Unsafe Shortcuts To Avoid

- Broad refactors.
- Disabling tests.
- Reverting unrelated user changes.
- Destructive git or shell commands.