---
applyTo: "{**/*.blade.php,**/resources/js/**/*.{js,ts}}"
---
# Alpine.js Overlay Instructions (Lightweight Client Interactivity)

These rules are an optional overlay for repositories that use Alpine.js.
They are additive to the frontend overlay and are commonly layered with Livewire or Inertia. Enable only when the repo actually uses Alpine.

## Documentation and Versions
- Use the official Alpine documentation as the primary reference: https://alpinejs.dev
- Follow the docs for the repo's installed stable version; verify directives and plugin APIs against the current docs before use.
- Cite the specific doc pages when a pattern is non-obvious.

## Usage
- Use Alpine for small declarative interactions (`x-data`, `x-bind`, `x-on`, `x-model`, `x-show`, `x-if`, `x-init`).
- Keep Alpine logic minimal; move complex behavior to the repo's framework state (Livewire components, Inertia pages, or dedicated JS modules).
- Avoid duplicating state that the server-side framework already owns.

## Interop
- With Livewire, share state through `$wire` and `@entangle` per the Livewire docs instead of copying values.
- With Inertia, read page props instead of refetching data Alpine can already see.
- Prefer official interop guidance over hand-rolled bridges.

## Accessibility
- Keep keyboard and focus behavior intact; hidden elements must stay reachable when shown.
- Ensure interactive controls have accessible names and states.

## Performance and Plugins
- Use watchers and `x-effect` sparingly; avoid heavy re-evaluation in render-critical markup.
- Add Alpine plugins (Persist, Mask, Focus, etc.) only when needed and per the official docs.

## Official References
- Alpine docs: https://alpinejs.dev
- Plugins: https://alpinejs.dev/plugins
