---
name: repo-onboarding
description: Quickly orient an agent to a repository by identifying source-of-truth docs, workflows, commands, and safety constraints.
---
# Skill: repo-onboarding

## When to Use
Use this skill at the start of work in an unfamiliar repository or when adopting this starter into a repo with existing conventions.

## Inputs Expected
- User goal or task type.
- Workspace root and repository structure.
- Existing `.github` assets and docs.
- Known validation commands or CI workflows.
- Any constraints from the user or team.

## Procedure
1. Read the repo baseline instructions first.
2. Identify source-of-truth docs, module manifest, workflows, hooks, agents, skills, prompts, and MCP templates.
3. Note established stack, test, and validation conventions only when the repo proves them.
4. Summarize the smallest workflow path for the user's task.
5. Call out missing docs or unclear ownership instead of guessing.

## Output Format
- Repo orientation summary
- Source-of-truth files
- Established commands and checks
- Relevant agents, skills, or prompts
- Missing context or risks
- Recommended next step

## Verification Checklist
- Claims are grounded in files that exist in the repository.
- Stack and test assumptions are not invented.
- MCP and high-risk automation remain disabled unless explicitly approved.
- The next step is narrow enough to act on.

## Safety Notes
- Do not edit files during onboarding unless the user asks for implementation.
- Do not collect or store secrets discovered during inspection.
- Stop and ask before destructive changes.

## Referenced Scripts Or Resources
- `.github/copilot-instructions.md`
- `.github/starter-modules.json`
- `docs/runbooks/starter-composition.md`
- `docs/runbooks/adopting-existing-github.md`