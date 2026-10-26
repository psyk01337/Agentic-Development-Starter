---
name: database-migration
description: Plan and execute schema or data migrations with backward compatibility, backfills, rollback, and production-safe sequencing.
---
# Skill: database-migration

## When to Use
Use this skill when a change adds, removes, or alters tables, columns, indexes, constraints, or stored data, or when data must be backfilled or transformed.

## Trigger Examples
- "Add a non-null column to a large table without downtime."
- "Rename a column that three services read."
- "Backfill a new field from existing rows."
- "Split this table and migrate the data."

## Checklist
- Identify every reader and writer of the affected schema: services, jobs, reports, analytics, ORM models, and external consumers.
- Classify the change: additive, destructive, type-changing, constraint-adding, or data-rewriting.
- Prefer expand-and-contract: add the new shape, dual-write or backfill, switch reads, then remove the old shape in a later change.
- Check lock behavior and cost: adding a defaulted column, adding a foreign key, building an index, or rewriting a table can lock or stall.
- Make the migration idempotent where the tool allows, and additive within one release.
- Write the backfill in bounded batches with a resume point; never update an unbounded table in one transaction.
- Keep the rollback path real: a down migration, a feature flag, or a documented forward fix.
- Test on a copy or fixture with production-like volume and verify both the schema and the resulting data.
- Confirm backups and a restore point exist before a destructive or type-changing migration.

## Safety Boundaries
- Do not drop or rename a column in the same release that stops writing it.
- Do not run an unbounded `UPDATE`, `DELETE`, or table rewrite against production without explicit approval.
- Do not assume a migration is reversible; state the rollback plan or say it is irreversible.
- Stop and ask before destructive data changes, cross-service contract changes, or anything that can lose data.
- Never run migrations against a production database from an agent session.

## Output Format (Strict)
1. Change classification
- What changes, which tables, and which readers and writers.

2. Sequencing
- The ordered releases or phases, including expand and contract.

3. Migration and backfill
- DDL, batching strategy, resume point, expected duration, and lock risk.

4. Verification
- Schema checks, row-count and checksum checks, and application read-back.

5. Rollback
- The real rollback path, or an explicit statement that the change is irreversible.

6. Handoff
- Recommended next agent, inputs, decision status, and approvals needed.
