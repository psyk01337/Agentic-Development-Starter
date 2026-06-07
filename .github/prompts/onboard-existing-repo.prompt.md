# Onboard Existing Repo

Use this prompt to assess how this starter should be adopted into an existing repository without overwriting project-specific workflow assets.

## Context To Inspect First

- `.github/copilot-instructions.md` and any existing `copilot-instructions.md`, `AGENTS.md`, or custom instruction files.
- `.github/starter-modules.json` when present.
- Existing `.github/workflows/`, hooks, prompts, agents, skills, and MCP configuration.
- `docs/runbooks/adopting-existing-github.md` and `docs/runbooks/starter-composition.md`.

## Deliverables

- Classify current assets as keep, merge, replace, or defer.
- Identify the minimal starter baseline to add first.
- List conflicts between existing repo rules and starter rules.
- Propose a phased adoption plan with validation after each phase.

## Safety Boundaries

- Do not overwrite existing `.github` assets without an explicit merge plan.
- Do not enable MCP servers, hooks, shell automation, or memory backends by default.
- Do not store secrets, credentials, production logs, or customer data in starter files.
- Stop and ask before destructive changes.

## Expected Output

- Current repo workflow inventory
- Recommended adoption mode: minimal, team, advanced, or enterprise
- Merge plan
- Validation commands
- Open decisions or approvals needed