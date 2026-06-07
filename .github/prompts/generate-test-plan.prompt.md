# Generate Test Plan

Use this prompt to create a lightweight QA plan for a change, release, or risky workflow.

## Context To Inspect First

- `.github/copilot-instructions.md` and test-related overlays under `.github/instructions/`.
- The changed files, acceptance criteria, and affected user or API flows.
- Existing tests, CI workflows, validation scripts, and known flaky areas.
- `docs/runbooks/agentic-dev.md` and `CHANGELOG.md` when release readiness matters.

## Deliverables

- Identify the riskiest flows and smallest useful validation set.
- Separate automated checks from manual checks.
- Note required fixtures, data, browsers, environments, or permissions.
- Define pass/fail criteria.

## Safety Boundaries

- Do not invent unavailable environments or test tools.
- Do not use production data or secrets in tests.
- Do not expand scope beyond the change unless risk requires it.
- Stop and ask before destructive changes.

## Expected Output

- Test scope
- Automated checks
- Manual checks
- Coverage gaps
- Release readiness verdict