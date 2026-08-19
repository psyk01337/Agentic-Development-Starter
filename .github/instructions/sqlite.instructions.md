---
applyTo: "{**/*.{sqlite,sqlite3,db},**/database/**/*.sql,**/config/database.php}"
---
# SQLite Overlay Instructions (Embedded Database)

These rules are an optional overlay for repositories that use SQLite.
They are additive to the general backend overlay and should only be enabled in repositories that actually use SQLite.

## Documentation and Versions
- Use the official SQLite documentation as the primary reference: https://www.sqlite.org/docs.html
- Prefer the latest stable SQLite release; SQLite has no LTS track. Check the release history and changelog before upgrading: https://www.sqlite.org/changes.html
- Verify version-specific behavior (SQL features, pragmas) against the docs for the version bundled by the repo's driver or runtime.
- Cite specific doc pages when a pattern is non-obvious.

## Schema and Migrations
- Keep schema changes in versioned migrations with documented rollback considerations.
- Avoid destructive migrations on shared or production data.
- Prefer explicit column types and constraints; validate `CHECK` and `NOT NULL` expectations in tests.

## Usage and Concurrency
- Parameterize all SQL; never build SQL from untrusted string interpolation.
- Use explicit transactions for multi-statement writes.
- Enable WAL mode and a sensible busy timeout for concurrent access where the repo's driver supports it: https://www.sqlite.org/wal.html
- Remember SQLite is single-writer; keep write transactions short.

## Backups and Operations
- Use the documented backup API (or `.backup` in the sqlite3 CLI) rather than copying a live database file: https://www.sqlite.org/backup.html
- Never commit database files that contain sensitive or production data.

## Testing
- Prefer in-memory or temporary-file databases for tests, following the repo's framework conventions.
- Cover migration rollback and constraint or validation failure paths.

## Official References
- SQLite docs: https://www.sqlite.org/docs.html
- Release history: https://www.sqlite.org/changes.html
- WAL mode: https://www.sqlite.org/wal.html
- Always verify against the docs for the SQLite version the repo actually uses.
