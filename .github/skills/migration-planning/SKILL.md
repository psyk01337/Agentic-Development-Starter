---
name: migration-planning
description: Plan a low-risk migration from existing workflow assets to this starter's modular repo-native model.
---
# Skill: migration-planning

## When to Use
Use this skill when a repository needs to adopt, trim, or upgrade starter modules without disrupting existing governance or CI.

## Inputs Expected
- Current `.github` structure and workflow assets.
- Desired adoption mode: minimal, team, advanced, or enterprise.
- Existing CI, security, release, and documentation rules.
- Constraints on rollout timing and approvals.
- Validation commands available in the target repo.

## Procedure
1. Inventory existing and starter assets by purpose.
2. Choose the minimal module set that satisfies the goal.
3. Identify conflicts, duplicate responsibilities, and default-disabled overlays.
4. Plan migration in small phases with validation after each phase.
5. Define rollback, approvals, and changelog expectations.

## Output Format
- Migration goal
- Current asset inventory
- Recommended module set
- Phased migration plan
- Validation and rollback plan
- Approvals needed

## Verification Checklist
- Existing project-specific rules are preserved unless explicitly replaced.
- Optional MCP, memory, orchestration, and runtime overlays stay disabled by default.
- Each phase has a validation path.
- Changelog and documentation updates are included.

## Safety Notes
- Do not overwrite existing workflow assets without a merge plan.
- Do not change application code as part of workflow migration.
- Stop and ask before destructive changes.

## Referenced Scripts Or Resources
- `docs/runbooks/starter-adoption.md`
- `docs/runbooks/adopting-existing-github.md`
- `docs/runbooks/starter-composition.md`
- `.github/starter-modules.json`