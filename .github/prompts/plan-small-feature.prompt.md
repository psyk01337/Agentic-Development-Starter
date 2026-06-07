# Plan Small Feature

Use this prompt to produce a concise, implementation-ready plan for a small feature or behavior change.

## Context To Inspect First

- `.github/copilot-instructions.md` and matching stack overlays under `.github/instructions/`.
- The nearest source-of-truth docs for the feature, such as product notes, API docs, ADRs, or runbooks.
- The owning implementation files, nearby tests, and existing validation commands.
- `CHANGELOG.md` and `DOC-CHANGELOG.md` expectations when behavior or docs will change.

## Deliverables

- State the acceptance criteria in testable language.
- Identify the smallest likely edit surface.
- List tests, docs, or changelog entries that should change.
- Name the first validation command or check to run after implementation.

## Safety Boundaries

- Do not turn planning into broad architecture redesign.
- Do not assume a stack, runtime, or test command that the repo does not establish.
- Do not plan changes to secrets, auth, deployment, or destructive data paths without explicit approval.
- Stop and ask before destructive changes.

## Expected Output

- Feature scope
- Assumptions
- Implementation plan
- Validation plan
- Risks and approval needs