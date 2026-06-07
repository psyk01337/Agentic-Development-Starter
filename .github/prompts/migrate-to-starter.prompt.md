# Migrate To Starter

Use this prompt to plan or execute migration of an existing project toward this starter's repo-native workflow model.

## Context To Inspect First

- Existing `.github` assets, CI workflows, hooks, prompts, agents, skills, and MCP config.
- `.github/starter-modules.json`, `docs/runbooks/starter-composition.md`, and `docs/runbooks/starter-adoption.md`.
- Project-specific security, testing, release, and documentation standards.
- Current README, changelogs, and ADRs.

## Deliverables

- Choose minimal, team, advanced, or enterprise adoption mode.
- Map starter modules to existing repo assets by purpose.
- Produce a phased migration plan with rollback and validation steps.
- Identify assets that must stay disabled until reviewed.

## Safety Boundaries

- Do not replace project-specific governance with starter defaults without approval.
- Do not enable dangerous tools, MCP servers, shell auto-execution, or memory providers by default.
- Do not alter runtime application behavior during workflow migration.
- Stop and ask before destructive changes.

## Expected Output

- Migration mode
- Asset mapping
- Phased plan
- Validation plan
- Approval gates and deferred risks