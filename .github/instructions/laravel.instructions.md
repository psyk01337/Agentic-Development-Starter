---
applyTo: "**/*.{php}"
---
# Laravel Overlay Instructions (PHP Web Framework)

These rules are an optional overlay for repositories that use Laravel.
They are additive to the PHP overlay and should only be enabled in repositories that actually use Laravel.

Use this file for Laravel-specific guidance. Layer the PHP overlay underneath and stack-specific overlays (Filament, Livewire, Inertia, Alpine, Valkey) on top where the repo uses those stacks.

## Documentation and Versions
- Use the official Laravel documentation as the primary reference: https://laravel.com/docs
- Prefer the latest stable Laravel release and consult the official support policy before upgrading: https://laravel.com/docs/releases
- Consult the docs for the exact major version this repo pins; APIs change between majors. Use the installed version's URL (for example `https://laravel.com/docs/<major>.x/...`) and cite specific pages when a pattern is non-obvious.
- Check release notes, upgrade guides (https://laravel.com/docs/upgrade), and security advisories before adding or upgrading any package.
- Prefer the latest stable PHP release from the official supported-versions table: https://www.php.net/supported-versions.php

## Routing and Controllers
- Keep routes, middleware, and controller contracts explicit and consistent with the repo's established style.
- Keep controllers thin; move business logic into services, actions, or the repo's established pattern.
- Validate inputs at the boundary using Form Requests or the repo's validation pattern.
- Apply authorization checks close to protected resources (policies and gates) rather than relying on authentication alone.

## Models and Data
- Use Eloquent following the repo's existing conventions for `fillable` vs `guarded`, casts, relationships, and scopes.
- Keep write operations transaction-safe (`DB::transaction`) when multiple records must change together.
- Create migrations for schema changes and document rollback considerations; avoid destructive migrations on shared data.
- Never build SQL from untrusted string interpolation; use the query builder or Eloquent parameterized statements.

## Queues, Jobs, and Scheduling
- Keep jobs idempotent and retry-safe with explicit timeouts, retries, and failure handling.
- Keep scheduled commands documented and use the repo's queue driver conventions.
- Avoid running long work synchronously inside web requests where a queue pattern exists.

## Caching and Sessions
- Use Laravel's cache and session abstractions rather than raw store access where possible.
- Keep cache keys namespaced, typed, and evictable; never cache secrets or full sensitive payloads.

## Logging and Errors
- Use structured log contexts with stable field names and request or trace identifiers.
- Never log secrets, tokens, or full sensitive payloads.
- Convert low-level exceptions into actionable, user-safe responses; do not leak internals.

## Testing
- Add feature and unit tests for changed behavior using the repo's runner (Pest or PHPUnit).
- Cover validation failures, authorization failures, and queue or retry paths.
- Add regression tests for production defects.

## Official References
- Laravel docs: https://laravel.com/docs
- Support policy: https://laravel.com/docs/releases
- Upgrade guides: https://laravel.com/docs/upgrade
- PHP supported versions: https://www.php.net/supported-versions.php
