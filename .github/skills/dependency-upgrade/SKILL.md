---
name: dependency-upgrade
description: Upgrade or add a dependency safely by checking advisories, changelogs, lockfile integrity, blast radius, and rollback before changing versions.
---
# Skill: dependency-upgrade

## When to Use
Use this skill when adding, removing, or changing a direct or transitive dependency, runtime, build tool, or base image.

## Trigger Examples
- "Upgrade React 18 to 19."
- "This package has a CVE; update it."
- "Replace this unmaintained library."
- "Bump the Node runtime."

## Checklist
- Read the official changelog and migration guide for every major and minor jump, not just the release notes summary.
- Check security advisories for the current and target versions, and confirm the target actually fixes the issue.
- Identify the blast radius: direct callers, lockfile changes, peer dependencies, native builds, and CI images.
- Verify the package name, publisher, and registry exactly; check publish date and download patterns for typosquatting or account takeover.
- Review install lifecycle scripts before accepting a new or updated package.
- Prefer the smallest safe bump. Do not combine an upgrade with unrelated refactors.
- Update the lockfile with the repo's package manager and commit it.
- Run the focused test, type-check, lint, and build for the affected workspace before broadening.
- Record the previous and new version, the reason, and the rollback command.

## Safety Boundaries
- Do not use open-ended ranges or bypass lockfile integrity in production manifests.
- Do not install from plain HTTP registries or with certificate verification disabled.
- Do not upgrade a security-critical package without confirming the advisory is resolved.
- Stop and ask before a major framework upgrade, a runtime change, or replacing a library across the codebase.
- Do not auto-merge minor or major dependency updates.

## Output Format (Strict)
1. Change
- Package, current and target versions, and reason.

2. Compatibility
- Breaking changes, migration steps, and peer or runtime constraints.

3. Blast radius
- Affected workspaces, call sites, and CI or deployment config.

4. Validation
- Commands run, results, and the focused surface tested.

5. Rollback
- The exact command or manifest revert.

6. Handoff
- Recommended next agent, inputs, decision status, and approvals needed.
