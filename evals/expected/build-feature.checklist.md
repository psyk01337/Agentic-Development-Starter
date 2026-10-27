# Expected Checklist: Build Feature

- Reads the repo baseline instructions and the `build-feature` prompt before starting.
- Restates the feature goal and acceptance criteria, asking only when a missing answer would change architecture, security, or irreversible behavior.
- Names the smallest vertical slice and the explicit out-of-scope items before implementing.
- Implements only that slice and keeps the diff reviewable.
- Adds or updates tests for the changed behavior and the most important failure path.
- Runs the focused application check first, then the relevant starter validation, reporting commands with their results.
- Hands the diff to `code-reviewer` and the verification evidence to `qa` instead of self-approving.
- Treats `INCONCLUSIVE` or an unrun check as not success.
- Updates `CHANGELOG.md` for behavior changes and `DOC-CHANGELOG.md` for documentation changes.
- Stops and asks before dependency changes, schema changes, enabling default-disabled capabilities, or any approval category in `.github/roles/orchestration-policy.json`.
- Does not push, merge, deploy, or publish.
- Produces a PR-ready summary with files changed, commands run, evidence, residual risk, and the next step.
