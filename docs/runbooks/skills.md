# Skills Runbook

This runbook gives teams quick example prompts for each starter skill so adoption is faster and more consistent.

## Core Workflow Skills

### `adr-authoring`

Use when a design or workflow decision should be recorded as an ADR.

Example prompts:

- `Use adr-authoring to draft an ADR for enabling the approval-gated orchestration overlay in this repo.`
- `Turn this architecture decision into an ADR using the repo template and keep it concise.`

### `bug-triage`

Use when symptoms are still ambiguous and the safest next step is to narrow the problem before implementation.

Example prompts:

- `Use bug-triage for this regression: users intermittently lose form state after navigation.`
- `Run bug-triage on this issue and separate confirmed evidence from likely causes.`

### `qa-test-plan`

Use when a feature or change needs an explicit minimum validation plan before signoff.

Example prompts:

- `Use qa-test-plan for the new account settings workflow and focus on risky user flows.`
- `Create a minimal QA test plan for this auth change, including failure cases and coverage gaps.`

### `pr-review`

Use when you want a findings-first review of correctness, regressions, and maintainability.

Example prompts:

- `Use pr-review on my current diff. Focus on correctness, tests, regressions, and docs impact.`
- `Review this change with pr-review and call out the smallest safe fixes first.`

### `security-check`

Use when a change touches auth, input handling, file or network access, secrets, or dependencies.

Example prompts:

- `Run security-check on this endpoint change and focus on authz, logging, and injection risk.`
- `Use security-check for these config changes and tell me whether any secret-handling or path risks were introduced.`

### `release-notes`

Use when you need concise user-facing and internal release summaries.

Example prompts:

- `Use release-notes for the merged changes in this sprint and separate user-facing notes from internal notes.`
- `Draft release notes for this week’s changes, including upgrade notes and verification.`

## Optional Overlay Skills

### `approval-gated-handoffs`

Use only when the repo has explicitly enabled the orchestration overlay and you need an approval-gated transition between specialists.

Example prompts:

- `Use approval-gated-handoffs to draft the next transition from tech-planner to senior-software-engineer.`
- `Coordinate the next specialist handoff with explicit approval and fallback to manual if approval is missing.`

### `api-scaffold`

Use when a repo has a stable backend pattern and you want a scaffold from a contract or endpoint spec.

Example prompts:

- `Use api-scaffold for POST /orders/{id}/cancel with auth required, reason:string, and 200/400/403/404 responses.`
- `Scaffold a queue consumer from this event contract using api-scaffold and include tests and docs stubs.`

### `ui-scaffold`

Use when a repo has an established UI framework and you want a structured screen or interaction scaffold.

Example prompts:

- `Use ui-scaffold for an account settings screen with profile edit, password update, and loading/error/empty/success states.`
- `Use ui-scaffold to draft the component structure and state model for this onboarding workflow.`

## Consistency Check

Use the starter skill checks to confirm the manifest and skill directories stay aligned:

- PowerShell: `.github/scripts/check-starter-skills.ps1`
- Shell: `.github/scripts/check-starter-skills.sh`

These checks verify that every skill path listed in `.github/starter-modules.json` exists and includes a `SKILL.md` file.

If you want one entry point for the broader starter checks, use:

- PowerShell: `.github/scripts/check-starter-workflow.ps1`
- Shell: `.github/scripts/check-starter-workflow.sh`
