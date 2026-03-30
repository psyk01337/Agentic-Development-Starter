---
applyTo: "**/*.{ts,tsx,js,jsx}"
---
# Frontend Overlay Instructions (JS/TS UI General)

These rules are an optional overlay for repositories that use JavaScript or TypeScript UI code. They are not the baseline for every repo using this starter.

Use this file for framework-agnostic frontend guidance.
If the repository uses React or Next.js, layer the dedicated framework overlays on top of this one rather than placing framework-specific rules here.

## Design and Structure
- Follow existing component naming conventions in this repository.
- Keep components small and composable; extract hooks/helpers when logic grows.
- Prefer predictable UI state handling for `loading`, `error`, `empty`, and `success`.
- Keep visual and behavior changes scoped to the requested feature.
- Adapt the guidance to the UI framework in use rather than assuming React-specific structure.
- Favor deterministic data flow and avoid hidden shared mutable state.
- Keep UI behavior accessible by default: semantics, keyboard flow, and clear focus states.

## State and Data Flow
- Keep view state local when possible; elevate only when multiple components truly need shared control.
- Keep data-fetching logic separated from presentation-heavy components where practical.
- Use explicit state transition handling instead of ad-hoc boolean combinations.

## Performance and UX
- Prevent avoidable re-renders and expensive synchronous work during user interactions.
- Use progressive rendering patterns for large lists or expensive views where the repo pattern supports it.
- Avoid layout shifts for loading states; reserve space where possible.

## Quality
- Add or update tests/stories when behavior changes.
- Preserve accessibility basics (labels, keyboard focus flow, semantic elements).
- Do not introduce new UI libraries unless explicitly requested.
- Keep test assertions focused on observable behavior rather than implementation internals.
