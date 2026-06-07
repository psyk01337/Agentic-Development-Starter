# Review Current Diff

Use this prompt to review the current working tree or pull request diff for correctness, risk, and missing validation.

## Context To Inspect First

- `.github/copilot-instructions.md`, `.github/AGENTS.md`, and applicable instruction overlays.
- The current diff and the files it touches.
- Nearby tests, schemas, runbooks, and source-of-truth docs for changed behavior.
- Recent changelog entries when the diff changes behavior or workflow contracts.

## Deliverables

- Report findings first, ordered by severity.
- Ground each finding in the changed file and expected behavior.
- Call out missing tests, docs, or validation evidence.
- State residual risk when no findings are present.

## Safety Boundaries

- Do not edit files during review.
- Do not approve work that violates security, auth, data, or contract rules.
- Do not ask for broad rewrites when a small fix addresses the issue.
- Stop and ask before destructive changes.

## Expected Output

- Findings
- Open questions or assumptions
- Missing validation
- Verdict: pass, needs-revision, or blocked