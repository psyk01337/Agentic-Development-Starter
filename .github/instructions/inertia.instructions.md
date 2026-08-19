---
applyTo: "{**/resources/js/**/*.{js,jsx,ts,tsx,vue,svelte},**/app/Http/Middleware/HandleInertiaRequests.php}"
---
# Inertia Overlay Instructions (Server-Driven SPA)

These rules are an optional overlay for repositories that use Inertia.js.
They are additive to the PHP and Laravel overlays on the server side and to the frontend overlay on the client side. Enable only when the repo actually uses Inertia.

## Documentation and Versions
- Use the official Inertia documentation as the primary reference: https://inertiajs.com
- Follow the docs for the repo's installed server adapter and client framework adapter (Vue, React, or Svelte); verify version-specific behavior against the current docs.
- Check release notes and upgrade guides before upgrading Inertia or its adapters.
- Cite the specific doc pages when a pattern is non-obvious.

## Data Flow and Props
- Keep page props small, serializable, and purposeful; avoid passing full models or large collections.
- Shape server payloads with resources, transformers, or the repo's established pattern.
- Use shared props via `HandleInertiaRequests.php` for data every page needs.

## Pages and Routing
- Keep one top-level page component per route and follow the repo's established directory convention.
- Use Inertia visits, partial reloads, and preserved state per the official docs instead of hand-rolled fetches.
- Keep form state in page components and render server-side validation errors consistently.

## Security
- Keep authorization authoritative on the Laravel side; never rely on hiding client-side UI.
- Validate all untrusted input at Laravel boundaries, including props that return to the server.

## Testing
- Test Laravel routes with feature tests for prop contracts and authorization.
- Use the repo's e2e conventions for cross-page flows and validation errors.

## Official References
- Inertia docs: https://inertiajs.com
- Server-side setup: https://inertiajs.com/server-side-setup
- Client-side setup: https://inertiajs.com/client-side-setup
