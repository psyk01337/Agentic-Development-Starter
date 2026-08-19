---
applyTo: "{**/app/Filament/**/*.php,**/resources/views/filament/**/*.blade.php}"
---
# Filament Overlay Instructions (Admin Panel)

These rules are an optional overlay for repositories that use Filament for admin panels.
They are additive to the PHP and Laravel overlays and should only be enabled in repositories that actually use Filament.

## Documentation and Versions
- Use the official Filament documentation as the primary reference: https://filamentphp.com/docs
- Follow the docs for the exact major version this repo pins (Filament 5 or the latest stable per the repo manifest). Filament's APIs changed significantly across majors — verify schema, action, and panel APIs against the installed version's docs instead of relying on memory.
- Check release notes, upgrade guides, and advisories before upgrading the Filament major or any panel package.
- Cite the specific doc pages when a pattern is non-obvious.

## Panels and Structure
- Keep panel files organized under `app/Filament/` following the repo's established layout.
- Register resources, pages, widgets, and theme assets exactly as the installed version's docs describe.
- Keep one clear convention per panel; avoid mixed registration styles.

## Resources, Forms, and Tables
- Keep schema definitions fluent, explicit, and readable; avoid nested closures that are hard to scan.
- Prefer Filament schema components over raw HTML inside resources and pages.
- Define table columns, filters, and actions close to the resource they describe.
- Keep loading, empty, and error states predictable using the version's documented patterns.

## Actions, Notifications, and Authorization
- Attach policy-based authorization to resources, pages, and actions; never rely on hidden navigation alone.
- Check permissions server-side for every action; client-side hiding is UX, not security.
- Keep notification messages user-safe and never include secrets or internals.

## Testing
- Use the installed version's documented testing helpers for resources and pages.
- Cover authorization denials, validation failures, and destructive action confirmations.
- Add regression tests for production defects.

## Official References
- Filament docs: https://filamentphp.com/docs
- Always verify against the docs for the repo's installed major version.
