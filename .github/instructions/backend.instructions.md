---
applyTo: "**/*.{py,pyi,sql}"
---
# Backend Overlay Instructions (Python/SQL)

These rules are an optional overlay for repositories that use Python or SQL in backend paths. They are not the baseline for every repo using this starter.

## API Conventions
- Keep endpoint contracts explicit: request schema, response schema, and error shape.
- Validate inputs at API boundaries and fail with structured, predictable errors.
- Return consistent status codes and avoid leaking internal exception details.
- Adapt the transport guidance to the repo's actual interface style: HTTP, RPC, jobs, events, or CLI.

## Data and Transactions
- Use existing DB access patterns in this repository.
- Keep write operations transaction-safe; avoid partial writes on failure.
- Add migrations for schema changes and document rollback considerations.

## Logging and Errors
- Use structured logs with stable field names.
- Include trace/context identifiers when available.
- Never log secrets, tokens, or full sensitive payloads.
- Convert low-level exceptions into actionable, user-safe API errors.

## Testing
- Add or update unit/integration tests for changed behavior.
- Cover unhappy paths and validation failures, not only happy paths.
- Use the repo's actual test runner and fixture style rather than assuming one.
