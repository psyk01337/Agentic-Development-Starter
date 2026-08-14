---
applyTo: "**/*.{ts,tsx,js,jsx}"
---
# Frontend Overlay Instructions (JS/TS UI General)

These rules are an optional overlay for repositories that use JavaScript or TypeScript UI code. They are not the baseline for every repo using this starter.

Use this file for framework-agnostic frontend guidance.
If the repository uses React or Next.js, layer the dedicated framework overlays on top of this one rather than placing framework-specific rules here.

## Dependencies
- Prefer the latest stable LTS release of Node.js and LTS versions of critical UI libraries (React, Next.js, etc.).
- Consult the official documentation for every UI framework, library, or dependency before using its APIs — do not rely on memory, outdated blog posts, or AI-generated patterns.
- Cite documentation references when the usage pattern is version-specific or non-obvious.
- Check for breaking changes, deprecation notices, and security advisories before upgrading any frontend dependency.

## Design and Structure
- Follow existing component naming conventions in this repository.
- When the project uses a component library or design system (e.g., shadcn/ui, Radix, MUI, Chakra), prefer its provided examples, sample blocks, and component primitives as a starting point — do not rebuild from scratch what the library already provides.
- Keep components small, composable, and modular; extract hooks/helpers when logic grows. Prefer single-responsibility components over monolithic all-in-one implementations.
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

## Error Handling
- Surface errors predictably: use error boundaries, toast notifications, or inline error states per the repo's established pattern.
- Avoid silent failures — every caught error should result in a user-visible fallback or a structured log.
- Keep `console.error` reserved for actionable diagnostics; strip debug logging before production builds where the repo's toolchain supports it.
- Never expose stack traces, raw error objects, or internal details in user-facing error states.

## Testing
- Add or update tests/stories when behavior changes.
- Keep test assertions focused on observable behavior rather than implementation internals.
- Do not introduce new UI libraries unless explicitly requested.

## Accessibility
- Preserve semantic markup, labels, keyboard focus flow, and ARIA states.
- Ensure interactive controls have accessible names and clear focus indicators.
- Test keyboard navigation for any changed interaction paths.
