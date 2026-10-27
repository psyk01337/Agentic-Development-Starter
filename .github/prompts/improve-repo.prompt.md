# Improve Repo

Use this prompt to run one bounded, autonomous improvement iteration on this repository. It turns the `process-improvement` agent into a repeatable loop: audit, select one friction-reducing change, implement, validate, record, and stop at the approval boundary.

## Context To Inspect First

- `.github/copilot-instructions.md`, `.github/agent-catalog.md`, and the relevant instruction overlays.
- `docs/runbooks/self-improvement.md` for the loop contract.
- Open issues labeled `improvement`, plus `checklist.md` if present (it is local-only and gitignored).
- The latest entries and open discrepancies in `CHANGELOG.md` and `DOC-CHANGELOG.md`.
- The current output of the umbrella validation: `bash .github/scripts/check-starter-workflow.sh` or the PowerShell twin.
- The nearest source-of-truth docs, ADRs, validators, and tests for the candidate change.
- The tool boundary in `.github/roles/tool-access.json`: `process-improvement` edits workflow assets but does not execute commands; `qa` executes validation and makes no edits.

## Deliverables

- Select exactly one improvement that removes friction from application development or closes a verified validation or documentation defect.
- Prefer the smallest reviewable diff with the strongest evidence; do not add new abstractions, agents, or framework layers.
- Implement the change on a feature branch or isolated worktree.
- Add or update the nearest regression test or check when behavior changes.
- Hand off focused and umbrella validation to `qa` when the implementing role cannot execute commands. Do not claim validation you did not observe.
- Update `CHANGELOG.md` for executable, configuration, prompt, or validator changes.
- Update `DOC-CHANGELOG.md` for runbook, instruction, or documentation changes.
- Record a decision trail entry with evidence pointers, not pasted output.
- Report the exact validation commands and results supplied by `qa` or the human operator.

## Safety Boundaries

- Stop and ask before destructive changes, broad refactors, cross-cutting renames, dependency changes, or changes to security-sensitive assets.
- Stop and ask before changing core-governance files, secrets handling, hooks, MCP configuration, memory policy, or approval policy.
- Do not push, merge, deploy, publish, or enable MCP servers, durable memory, or high-risk automation.
- Do not invent repository files, benchmark results, or completed validation.
- Do not select work just to keep the loop busy; if no qualifying improvement exists, report that and stop.
- Stop after two failed repair attempts on the same item and report the blocker.
- Keep secrets, credentials, tokens, and raw production data out of the trail and changelogs.

## Expected Output

- Selected improvement and why it outranks the alternatives
- Files changed and the smallest reviewable diff
- Validation commands, exit codes, and relevant results from `qa` or the human operator
- Changelog and decision-trail locations
- Residual risk, approval needed, and the next candidate
- A PR-ready summary that a human can review without replaying the session
