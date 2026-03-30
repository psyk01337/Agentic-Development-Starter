---
applyTo: "{**/*.{test,spec}.{ts,tsx,js,jsx},**/{__tests__,test,tests}/**/*.{ts,tsx,js,jsx}}"
---
# Frontend Test Overlay (Vitest + React Testing Library)

These rules are an optional overlay for repositories that use Vitest with React Testing Library.
They are additive to the frontend and React overlays and should only be enabled when this test stack is established.
The `applyTo` pattern intentionally targets test files and test directories rather than all TS/JS source files.

## Test Strategy
- Prefer behavior-focused tests over implementation-detail assertions.
- Keep unit and component tests small, deterministic, and fast.
- Cover happy paths, edge cases, and failure modes for changed behavior.
- Add regression tests for production defects.

## RTL Usage
- Query elements by role, label text, and visible user-facing affordances before falling back to test ids.
- Assert observable outcomes users experience, not internal state shape.
- Keep setup concise; extract reusable render helpers only when duplication becomes meaningful.
- Avoid brittle snapshot-heavy tests for interactive surfaces.

## Async and Timing
- Use async-aware utilities for state transitions and network-driven updates.
- Avoid arbitrary sleeps and timer-dependent flakiness.
- Keep fake timer usage explicit and reset timers between tests when needed.

## Mocking and Isolation
- Mock external boundaries (network, storage, time) while keeping UI behavior realistic.
- Do not mock the unit under test itself.
- Keep mock behavior explicit per test; avoid hidden global mutations.

## Coverage and Quality
- Prioritize meaningful branch coverage in critical interaction paths.
- Keep test names intent-revealing and scenario-specific.
- Use the repository's lint and test conventions for TS/JS test files.
