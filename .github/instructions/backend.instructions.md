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
- Centralize exception handling in framework handlers or middleware instead of per-endpoint `try/except` blocks.
- Distinguish expected client errors from unexpected server errors; log the unexpected ones with full context.

## API Conventions
- Keep endpoint contracts explicit: request schema, response schema, and error shape.
- Validate inputs at API boundaries and fail with structured, predictable errors.
- Return consistent status codes and avoid leaking internal exception details.
- Adapt the transport guidance to the repo's actual interface style: HTTP, RPC, jobs, events, or CLI.
- Make mutating endpoints idempotent where feasible (idempotency keys, deduplication) so safe retries do not double-apply side effects.
- Add pagination (limit plus cursor or offset) to list endpoints and document default and maximum page sizes.
- Return stable machine-readable error codes alongside HTTP status so clients can branch without parsing messages.
- Keep read and write paths separated where the repo pattern supports it (CQRS-lite), without over-engineering small services.

## Data and Transactions
- Use existing DB access patterns in this repository.
- Keep write operations transaction-safe; avoid partial writes on failure.
- Add migrations for schema changes and document rollback considerations.
- Parameterize SQL queries; never build SQL from untrusted string interpolation.
- Avoid N+1 query patterns: batch reads with joins or eager loading, and verify query counts when touching hot paths.
- Add indexes for columns used in filters and sorts; confirm choices with `EXPLAIN` or the repo's equivalent before shipping.
- Use optimistic locking or row versioning for concurrent updates where lost updates would matter.
- Keep migrations reversible where practical and test upgrade plus downgrade locally before merging.

## Concurrency and I/O
- Never block the event loop with synchronous I/O inside async request paths.
- Set explicit timeouts on outbound calls and enforce cancellation on shutdown or deadline.
- Bound background-task queues and worker counts; retry with exponential backoff and a dead-letter path.
- Use connection pooling with sane size and timeout limits instead of per-request connections.
- Guard shared mutable state with the repo's concurrency primitives and document the chosen isolation level.

## Security
- Enforce authorization per protected resource and operation, not just authentication at the door.
- Validate and constrain inputs at boundaries: types, ranges, lengths, and enum membership before business logic.
- Use least-privilege database credentials and the repo's secrets management pattern; never read secrets from env at module import time when the repo's tooling can inject them safely.
- Redact secrets, tokens, and PII from logs, errors, and traces; include a stable request identifier for correlation instead.

## Dependency and Runtime Hygiene
- Prefer the latest stable LTS Python release (e.g., 3.12, 3.13) and LTS versions of critical libraries (Django, SQLAlchemy, Celery, etc.).
- Prefer the repository's dependency management pattern and pin versions where the repo expects lock or constraints files.
- Consult each dependency's official documentation for correct usage patterns, configuration, and version-specific behavior before implementation. Cite documentation references when the pattern is non-obvious.
- Check for security advisories, deprecation warnings, and breaking-change notices before adding or upgrading any Python package.
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
- Prefer integration tests around real boundaries (API, DB, queue) over unit-only coverage.
- Replace only external side effects (network, clock, storage) with test doubles.
- Test idempotency and retry behavior for any endpoint or job that claims them.
