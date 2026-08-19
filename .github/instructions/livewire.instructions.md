---
applyTo: "{**/app/Livewire/**/*.php,**/app/Http/Livewire/**/*.php,**/resources/views/livewire/**/*.blade.php}"
---
# Livewire Overlay Instructions (Server-Driven UI)

These rules are an optional overlay for repositories that use Livewire.
They are additive to the PHP and Laravel overlays and should only be enabled in repositories that actually use Livewire.

## Documentation and Versions
- Use the official Livewire documentation as the primary reference: https://livewire.laravel.com/docs
- Follow the docs for the exact major version this repo pins (Livewire 4 or the latest stable per the repo manifest). APIs and directives changed across majors — verify component, property, and testing APIs against the installed version's docs instead of relying on memory.
- Check release notes and upgrade guides before upgrading the Livewire major.
- Cite the specific doc pages when a pattern is non-obvious.

## Components and State
- Keep public properties minimal and typed; they are the client contract.
- Prefer computed properties for derived state instead of duplicating it.
- Keep components single-purpose and split into smaller components when responsibilities mix.
- Use lifecycle hooks sparingly and idempotently.

## Templates and Directives
- Keep one root element per Livewire Blade view.
- Use `wire:` directives per the installed version's docs instead of hand-rolled JS where possible.
- Keep heavy client behavior out of Livewire views; use the repo's Alpine.js pattern for interop.

## Validation and Authorization
- Validate user input server-side with the version's documented validation patterns (attributes, rules, or form objects).
- Treat client-side validation as UX only; server-side validation is authoritative.
- Re-check authorization server-side in every action; never trust client-mutated public properties.

## Performance
- Keep network payloads small; avoid passing large collections or models into public properties.
- Paginate, defer, or lazy-load heavy data using the version's documented features.
- Avoid redundant round-trips in watchers and computed chains.

## Testing
- Use the installed version's documented test helpers (for example, `Livewire::test()` in Livewire 3) and follow the current docs for the repo's major.
- Cover authorization denials, validation failures, and lifecycle behavior.
- Add regression tests for production defects.

## Official References
- Livewire docs: https://livewire.laravel.com/docs
- Always verify against the docs for the repo's installed major version.
