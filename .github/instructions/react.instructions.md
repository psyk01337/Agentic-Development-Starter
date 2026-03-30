---
applyTo: "**/*.{ts,tsx,js,jsx}"
---
# React Overlay Instructions (Component UI)

These rules are an optional overlay for repositories that use React.
They are additive to the general frontend overlay and should only be enabled where React is the established framework.

## Component Boundaries
- Keep components focused and composable; extract hooks for reusable stateful logic.
- Prefer explicit props over implicit cross-component coupling.
- Keep presentational and data-orchestration responsibilities separated where practical.

## Rendering and State
- Avoid unnecessary re-renders by stabilizing props and memoizing expensive derived values when warranted.
- Prefer deterministic state transitions over scattered boolean flags.
- Keep effects idempotent and narrowly scoped to required dependencies.
- Avoid deriving state in multiple places when one source of truth is sufficient.

## Data and Side Effects
- Keep network and storage side effects out of render paths.
- Handle loading, error, empty, and success states explicitly.
- Prevent stale updates in async flows using cancellation or guard patterns.

## Accessibility and UX
- Preserve semantic markup and keyboard navigation flow.
- Keep focus management explicit for dialogs, menus, and route-level transitions.
- Ensure interactive controls have accessible names and states.

## Testing
- Test behavior from the user's perspective rather than implementation details.
- Cover state transitions and edge cases, not only happy-path rendering.
- Prefer repository-standard component test tooling and patterns.
