---
applyTo: "{**/*.{sql,mysql},**/migrations/**/*.sql,**/config/database.php}"
---
# MariaDB Overlay Instructions (Relational Database)

These rules are an optional overlay for repositories that use MariaDB.
They are additive to the general backend overlay and should only be enabled in repositories that actually use MariaDB.

## Documentation and Versions
- Use the official MariaDB documentation as the primary reference: https://mariadb.com/kb/en/documentation/
- Prefer the latest stable MariaDB release per the official maintenance policy (each major is maintained for five years): https://mariadb.org/about/#maintenance-policy
- MariaDB is not MySQL: verify behavior, data types, and SQL features against the MariaDB docs for the version in use, not MySQL documentation.
- Check release notes and upgrade guidance before major upgrades.

## Schema and Migrations
- Keep schema changes in versioned, transaction-safe migrations with documented rollback considerations.
- Prefer InnoDB tables, utf8mb4 character sets, and strict SQL mode where the repo conventions allow.
- Prefer explicit data types, constraints, and foreign keys.

## Queries and Data Safety
- Parameterize all SQL; never build SQL from untrusted string interpolation.
- Keep multi-statement writes inside transactions to avoid partial writes.
- Avoid unbounded result sets and long-running locks in request paths.

## Backups and Replication
- Use official tooling (for example `mariadb-backup`) for backups per the current docs; do not copy live data directories blindly.
- Keep replication and failover configuration in documented infrastructure code, not ad-hoc commands.

## Testing
- Test against a dedicated MariaDB test database per the repo's framework conventions.
- Cover migration rollback, constraint violations, and collation or character-set edge cases.

## Official References
- MariaDB docs: https://mariadb.com/kb/en/documentation/
- Maintenance policy: https://mariadb.org/about/#maintenance-policy
- Always verify against the docs for the MariaDB version the repo actually uses.
