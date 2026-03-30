---
applyTo: "{**/*.{e2e,cy}.{ts,tsx,js,jsx},**/{e2e,playwright,cypress}/**/*.{ts,tsx,js,jsx}}"
---
# Frontend E2E Overlay (Playwright/Cypress)

These rules are an optional overlay for repositories that use browser e2e testing frameworks such as Playwright or Cypress.
They are additive to frontend framework overlays and should only be enabled in repositories with an established e2e stack.
The `applyTo` pattern intentionally targets e2e-oriented file names and directories.

## E2E Scope and Value
- Use e2e tests for high-risk user journeys and critical integration boundaries.
- Avoid duplicating every unit/component case at e2e level.
- Keep scenarios focused on user outcomes and cross-layer behavior.

## Reliability and Flake Control
- Prefer robust selectors based on stable roles or explicit test attributes.
- Avoid brittle selectors coupled to styling or DOM structure.
- Use built-in waiting and retry mechanisms instead of arbitrary sleeps.
- Ensure tests are isolated and can run in any order.

## Data and Environment
- Use deterministic test fixtures or seeded data strategies.
- Keep environment preconditions explicit per suite.
- Clean up side effects across tests to prevent cross-test pollution.
- Document required env vars and secrets handling for CI runs.

## Observability and Debugging
- Capture screenshots, traces, or videos according to repo conventions when failures occur.
- Log enough context to triage failures without exposing secrets.
- Preserve reproducible failure artifacts for flaky test diagnosis.

## Pipeline and Coverage
- Keep smoke tests fast for PR checks; run deeper suites in scheduled or gated pipelines where appropriate.
- Ensure at least one negative-path journey is covered for each critical flow changed.
- Revisit failing/flaky tests promptly and quarantine only with an explicit follow-up ticket.
