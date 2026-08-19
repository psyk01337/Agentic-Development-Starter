---
applyTo: "{**/*.{sql,pgsql},**/migrations/**/*.sql,**/config/database.php}"
---
# PostgreSQL Overlay Instructions (Relational Database)

These rules are an optional overlay for repositories that use PostgreSQL.
They are additive to the general backend overlay and should only be enabled in repositories that actually use PostgreSQL.

## Documentation and Versions
- Use the official PostgreSQL documentation as the primary reference: https://www.postgresql.org/docs/
- Prefer the latest supported major per the official versioning policy (a new major is released yearly and each major is supported for five years): https://www.postgresql.org/support/versioning/
- Consult the docs for the exact major version the repo connects to; cite specific pages when a pattern is non-obvious.
- Check release notes and upgrade guidance before major upgrades.

## Schema and Migrations
- Keep schema changes in versioned, transaction-safe migrations with documented rollback considerations.
- Prefer explicit data types, constraints, and foreign keys; document deliberate denormalizations.
- Review query plans (`EXPLAIN`) for changed or data-sensitive queries and add indexes where the repo pattern requires.

## Queries and Data Safety
- Parameterize all SQL; never build SQL from untrusted string interpolation.
- Keep multi-statement writes inside transactions to avoid partial writes.
- Avoid long-running locks and unbounded result sets in request paths.

## Security and Access
- Use least-privilege roles and scoped grants; do not run application code as a superuser.
- Never commit credentials; document required variables in `.env.example`.

## Testing
- Test against a dedicated test database per the repo's framework conventions.
- Cover migration rollback, constraint violations, and concurrency edge cases.

## Official References
- PostgreSQL docs: https://www.postgresql.org/docs/
- Versioning policy: https://www.postgresql.org/support/versioning/
- Always verify against the docs for the PostgreSQL major version the repo actually uses.
