---
applyTo: "**/*"
---
# Core Starter Instructions

These rules are the language-agnostic baseline for repositories that use this starter.

## Scope And Sources Of Truth
- Start from the repo's actual source-of-truth docs and code, not from starter examples.
- If expected docs do not exist, say so explicitly and proceed from the smallest reliable evidence.
- Apply stack-specific overlays only when the current file type and repo conventions justify them.

## Dependencies and Documentation
- Prefer the latest stable LTS (Long Term Support) release for runtime platforms and critical dependencies.
- Consult the official documentation for every framework, library, and dependency before using it — do not rely on memory or outdated examples.
- Cite references and documentation links when making implementation decisions involving third-party APIs, configuration, or version-specific behavior.
- Check for security advisories, deprecation notices, and breaking-change announcements before adding or upgrading a dependency.
- Verify usage patterns against current official documentation, not against outdated tutorials or AI-generated examples.

## Delivery
- Keep diffs small, reviewable, and tightly scoped to the request.
- Fix root causes when feasible; avoid surface-only patches that preserve unclear behavior.
- When behavior changes, update the nearest relevant tests and docs in the same change.
- Prefer a regression test for defect fixes and behavior changes; when a test cannot run, say why.
- Report validation evidence (commands run and results) before treating a change as complete.
- Prefer extending existing patterns before introducing new abstractions, roles, or workflow layers.

## Definition Of Done
A change is done only when all of these are true:

- The requested behavior works and the smallest relevant check passes.
- The diff stays inside the agreed scope and write set.
- Tests cover the new behavior and the most important failure path.
- Related docs, changelogs, and contracts are updated in the same change.
- Validation evidence is recorded as commands and results, not as a claim.
- Known gaps, deferred work, and residual risk are written down.

If any item cannot be met, say which one and why instead of marking the work complete.

## Blast Radius And Rollback
- Before a risky change, name what breaks if it is wrong and how it would be reverted.
- Prefer changes that can ship behind a flag, in phases, or in an independently revertible commit.
- Treat schema, public contract, and dependency changes as high blast radius even when the diff is small.
- Never describe a change as safe to roll back unless a rollback path actually exists.

## Generated, Vendored, And Migrated Code
- Do not hand-edit generated files. Change the generator, schema, or source template instead.
- Do not modify vendored third-party code. Wrap it, patch it upstream, or record the exception.
- Treat migrations as append-only after they have run anywhere shared. Fix forward with a new migration.
- Keep generated artifacts out of review noise; regenerate them with the documented command.

## Choosing The Check
- Run the closest failing check first: the single test, the single package, the single file.
- Broaden only when the focused check passes or the change crosses a boundary the focused check cannot see.
- Prefer the repository's documented command over an ad hoc one.
- A check that cannot run is a gap to report, not a pass.

## Collaboration
- State assumptions quickly when context is missing or conflicting.
- Separate confirmed facts from inferences when scanning or reviewing a repo.
- Prefer modular additions over cross-cutting rewrites when evolving starter assets.

## Safety
- Validate untrusted input at boundaries.
- Keep commands explicit, reviewable, and least-privilege by default.
- Never store secrets or live credentials in source-controlled files, examples, or logs.
- For the full security baseline (OWASP-aligned rules, supply chain, cryptography, and secrets handling), see `.github/instructions/security.instructions.md`.