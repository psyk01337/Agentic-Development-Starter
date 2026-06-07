# Implement Small Diff

Use this prompt to implement a narrow change with the smallest reviewable diff and immediate validation.

## Context To Inspect First

- `.github/copilot-instructions.md` and any instruction overlays that match the touched files.
- The nearest owning code path, neighboring tests, and call sites.
- Relevant ADRs, API contracts, runbooks, or acceptance criteria.
- Existing validation scripts or test commands for the touched slice.

## Deliverables

- Make the focused edit only.
- Update nearest tests or docs when behavior changes.
- Update `CHANGELOG.md` for executable or behavior-affecting changes.
- Update `DOC-CHANGELOG.md` for documentation changes.
- Report validation evidence.

## Safety Boundaries

- Do not refactor unrelated code.
- Do not revert user changes unless explicitly requested.
- Do not add dependencies unless the repo pattern and task require them.
- Stop and ask before destructive changes.

## Expected Output

- Change summary
- Files changed
- Validation run
- Residual risks
- Recommended next review or QA step