---
applyTo: "**/*.{py,pyi}"
---
# FastAPI Overlay Instructions (Python API)

These rules are an optional overlay for repositories that use FastAPI.
They are additive to the general backend Python/SQL overlay and should only be enabled in repositories that actually use FastAPI.

## Route and Contract Design
- Keep route paths, methods, and status codes explicit and consistent.
- Define request and response models explicitly; avoid implicit response shapes.
- Use `response_model` (or equivalent repo pattern) to enforce output contracts.
- Keep route handlers thin; move business logic into service modules.

## Validation and Schemas
- Use Pydantic models for boundary validation and serialization.
- Prefer explicit field constraints and defaults over ad-hoc runtime checks.
- Avoid returning raw ORM entities directly from endpoints.
- Keep backward compatibility in mind when evolving public schemas.

## Dependency Injection and Lifecycle
- Use FastAPI dependency injection for auth, DB sessions, and shared resources.
- Keep dependencies side-effect free and request-scoped where appropriate.
- Use startup and shutdown hooks for long-lived resources.
- Ensure dependencies release resources correctly on both success and failure paths.

## Async and I/O Safety
- Use `async def` only when the call chain is async-safe.
- Do not block the event loop with synchronous network or database calls.
- Offload CPU-bound work to background workers or separate execution paths.
- Keep timeout and cancellation behavior explicit for outbound calls.

## Error Handling and Security
- Raise `HTTPException` (or established repo equivalents) with safe, consistent error bodies.
- Add authentication and authorization checks at route boundaries.
- Validate and sanitize all untrusted inputs, including query/path/header values.
- Do not leak internals in 4xx or 5xx responses.

## Observability
- Use middleware or shared hooks for correlation IDs, request logging, and timing.
- Log request outcomes with stable structured fields.
- Never log secrets, tokens, or full sensitive payloads.

## Testing
- Add route tests for happy path and failure cases.
- Cover validation failures, auth failures, and dependency failure scenarios.
- Use the repository's preferred FastAPI test client and fixture style.
- Verify OpenAPI and schema changes when endpoint contracts are modified.
