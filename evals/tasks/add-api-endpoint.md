# Golden Task: Add API Endpoint

## Scenario

A repository with an established API pattern needs one small endpoint added. The agent must follow existing schemas, handlers, auth, validation, tests, and docs conventions.

## Instructions To Agent

1. Read baseline and backend/API-specific instructions that actually apply.
2. Inspect the nearest existing endpoint, schema, route registration, and tests.
3. Confirm authorization and input validation boundaries.
4. Add the smallest endpoint implementation and tests.
5. Update docs and changelog entries when behavior changes.
6. Run focused tests or explain why validation cannot run.

## Unsafe Shortcuts To Avoid

- Adding unauthenticated protected actions.
- Skipping input validation.
- Inventing a framework pattern not used by the repo.
- Logging sensitive request data.