---
applyTo: "**/*.{py,pyi,sql}"
---
# Backend Overlay Instructions (Python/SQL General)

These rules are an optional overlay for repositories that use Python or SQL in backend paths. They are not the baseline for every repo using this starter.

Use this file for general backend Python and SQL guidance.
If the repository uses FastAPI, layer the dedicated FastAPI overlay on top of this one rather than placing framework-specific rules here.

## Python Style and Readability
- Follow PEP 8 style conventions and use the repository's configured formatter or linter as the final source of truth.
- Prefer clear names, small functions, and explicit control flow over dense one-liners.
- Keep modules focused; split files when responsibilities become mixed.
- Avoid wildcard imports and avoid hidden side effects at import time.

## Typing and Interfaces
- Add type hints to public functions, methods, and return values.
- Keep input and output contracts explicit with typed structures.
- Use `Protocol`, `TypedDict`, `dataclass`, or existing schema patterns when they improve interface clarity.
- Avoid introducing `Any` unless there is a concrete compatibility reason.

## Python Error Handling
- Raise precise exceptions with actionable context.
- Do not swallow exceptions silently; either handle them fully or re-raise with context.
- Keep user-facing errors safe and structured; avoid exposing stack traces or internals in API responses.
- Use `finally` or context managers for cleanup-sensitive resources.

## API Conventions
- Keep endpoint contracts explicit: request schema, response schema, and error shape.
- Validate inputs at API boundaries and fail with structured, predictable errors.
- Return consistent status codes and avoid leaking internal exception details.
- Adapt the transport guidance to the repo's actual interface style: HTTP, RPC, jobs, events, or CLI.

## Data and Transactions
- Use existing DB access patterns in this repository.
- Keep write operations transaction-safe; avoid partial writes on failure.
- Add migrations for schema changes and document rollback considerations.
- Parameterize SQL queries; never build SQL from untrusted string interpolation.

## Dependency and Runtime Hygiene
- Prefer the repository's dependency management pattern and pin versions where the repo expects lock or constraints files.
- Keep third-party additions minimal and justified.
- Avoid global mutable state for request-sensitive or concurrency-sensitive logic.
- Prefer context managers for file handles, network clients, and DB sessions.

## Logging and Errors
- Use structured logs with stable field names.
- Include trace/context identifiers when available.
- Never log secrets, tokens, or full sensitive payloads.
- Convert low-level exceptions into actionable, user-safe API errors.

## Testing
- Add or update unit/integration tests for changed behavior.
- Cover unhappy paths and validation failures, not only happy paths.
- Use the repo's actual test runner and fixture style rather than assuming one.
- Add regression tests for production defects to prevent recurrence.
