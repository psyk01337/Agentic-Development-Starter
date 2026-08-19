---
applyTo: "{**/config/*.php,**/.env.example,**/app/**/*.php}"
---
# Valkey Overlay Instructions (RESP Store)

These rules are an optional overlay for repositories that use Valkey as a cache, queue, session, or data store.
They are additive to the PHP and Laravel overlays where Laravel is the host framework. Enable only when the repo actually uses Valkey.

## Documentation and Versions
- Use the official Valkey documentation as the primary reference: https://valkey.io/docs
- Valkey speaks the RESP protocol; check the current Laravel docs (https://laravel.com/docs/redis) for first-class Valkey configuration support in the repo's installed version, and otherwise treat Valkey as a RESP-compatible endpoint for the repo's redis client (phpredis or predis).
- Verify client-library compatibility (phpredis: https://github.com/phpredis/phpredis, predis: https://github.com/predis/predis) against the current Valkey release before upgrading either side.
- Do not assume feature parity with Redis in every client; confirm behavior against the Valkey docs.

## Configuration
- Keep connection config in `config/` files plus environment variables; never commit real credentials.
- Document scheme, host, port, database, and TLS variables in `.env.example`.
- Pin client library versions per the repo's lockfile conventions.

## Usage
- Prefer Laravel's cache, queue, session, and redis abstractions over raw client calls where they exist.
- Use namespaced, typed keys with explicit TTLs; never store secrets or full sensitive payloads.
- Keep queue jobs idempotent and retry-safe.

## Operational Safety
- Never ship destructive commands (for example `FLUSHALL`) in code paths.
- Avoid blocking commands and full-key scans in request paths.
- Keep connections pooled and timeouts explicit.

## Testing
- Test business logic against the repo's fast in-memory test stores by default.
- Add integration coverage only for Valkey-specific behavior (TTL, serialization, locking) where the repo requires it.

## Official References
- Valkey docs: https://valkey.io/docs
- Laravel Redis docs: https://laravel.com/docs/redis
- Always verify against the docs for the repo's installed versions.
