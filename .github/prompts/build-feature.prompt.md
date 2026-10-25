# Build Feature

Use this prompt as the single entry point for delivering one application feature through the starter's guided workflow. It replaces the manual chain of separate planning, implementation, review, and test-plan prompts with one bounded feature loop.

## Context To Inspect First

- `.github/copilot-instructions.md`, `.github/AGENTS.md`, and the instruction overlays that match the stack and touched paths.
- The project's real source-of-truth docs: PRD, architecture, API contract, ADRs, and acceptance criteria.
- The nearest application code, tests, package manifests, and validation commands.
- `.github/roles/tool-access.json` to confirm which agent owns planning, implementation, review, and verification.
- `docs/runbooks/agentic-dev.md` for the guided handoff contract.

## Deliverables

- Restate the feature goal and acceptance criteria; ask only when a missing answer changes architecture, security, or irreversible behavior.
- Produce a short implementation plan with the smallest vertical slice and explicit out-of-scope items.
- Implement the slice with `senior-software-engineer` or the matching stack overlay agent.
- Add or update tests for the changed behavior and the most important failure path.
- Run the focused application checks first, then the relevant starter validation.
- Hand the diff to `code-reviewer` and the verification evidence to `qa`.
- Update `CHANGELOG.md` for behavior changes and `DOC-CHANGELOG.md` for documentation changes.
- Produce a PR-ready summary with files changed, commands run, evidence, residual risk, and the next step.

## Safety Boundaries

- Do not broaden the feature beyond the stated acceptance criteria.
- Do not refactor unrelated code or rename cross-cutting symbols.
- Do not add dependencies, change schemas, or enable MCP servers, durable memory, or high-risk automation without explicit approval.
- Do not push, merge, deploy, or publish.
- Stop and ask before destructive changes, security-sensitive changes, or any change that crosses an approval category in `.github/roles/orchestration-policy.json`.
- Keep secrets, credentials, tokens, and production data out of code, logs, tests, and changelogs.
- If validation cannot run, report it as `NOT_VERIFIED`; do not claim success.

## Expected Output

- Feature goal and acceptance criteria
- Implementation plan and out-of-scope items
- Files changed and the smallest reviewable diff
- Tests added or updated, with commands and results
- `code-reviewer` findings and `qa` verification verdict
- Changelog entries and residual risk
- Recommended next step and approval needed