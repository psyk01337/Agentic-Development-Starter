---
applyTo: "**/*.{ts,tsx,js,jsx}"
---
# Frontend Instructions

## Design and Structure
- Follow existing component naming conventions in this repository.
- Keep components small and composable; extract hooks/helpers when logic grows.
- Prefer predictable UI state handling for `loading`, `error`, `empty`, and `success`.
- Keep visual and behavior changes scoped to the requested feature.

## React and Rendering
- Avoid unnecessary re-renders: memoize expensive derived values and stabilize props where appropriate.
- Keep data-fetching and transformation logic outside render-heavy components.
- Prefer explicit prop contracts over implicit shared state.

## Quality
- Add or update tests/stories when behavior changes.
- Preserve accessibility basics (labels, keyboard focus flow, semantic elements).
- Do not introduce new UI libraries unless explicitly requested.
