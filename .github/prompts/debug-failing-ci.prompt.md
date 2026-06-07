# Debug Failing CI

Use this prompt to triage and fix failing CI with a narrow, evidence-first workflow.

## Context To Inspect First

- The failing workflow file, job logs, exact command, and failing step.
- `.github/copilot-instructions.md`, relevant stack overlays, and validation scripts.
- Recent changes to dependencies, scripts, tests, hooks, or CI configuration.
- Nearest tests or scripts that reproduce the failure locally.

## Deliverables

- Summarize the failing command and observed error.
- Identify the most likely root cause and one cheap disconfirming check.
- Make the smallest fix when the cause is local and clear.
- Record validation or explain why it could not be run.

## Safety Boundaries

- Do not silence tests, disable checks, or loosen policy to make CI pass without approval.
- Do not rotate credentials or edit deployment secrets in source-controlled files.
- Do not rewrite unrelated workflows while debugging one failure.
- Stop and ask before destructive changes.

## Expected Output

- Failure summary
- Root cause or narrowed hypothesis
- Fix summary
- Validation run
- Remaining CI risk