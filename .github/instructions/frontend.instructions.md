---
applyTo: "**/*.{ts,tsx,js,jsx}"
---
# Frontend Overlay Instructions (JS/TS UI)

These rules are an optional overlay for repositories that use JavaScript or TypeScript UI code. They are not the baseline for every repo using this starter.

## Design and Structure
- Follow existing component naming conventions in this repository.
- Keep components small and composable; extract hooks/helpers when logic grows.
- Prefer predictable UI state handling for `loading`, `error`, `empty`, and `success`.
- Keep visual and behavior changes scoped to the requested feature.
- Adapt the guidance to the UI framework in use rather than assuming React-specific structure.

## React and Rendering
- Avoid unnecessary re-renders: memoize expensive derived values and stabilize props where appropriate.
- Keep data-fetching and transformation logic outside render-heavy components.
- Prefer explicit prop contracts over implicit shared state.

## Quality
- Add or update tests/stories when behavior changes.
- Preserve accessibility basics (labels, keyboard focus flow, semantic elements).
- Do not introduce new UI libraries unless explicitly requested.
