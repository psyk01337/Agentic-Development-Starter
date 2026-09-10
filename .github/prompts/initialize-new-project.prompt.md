# Initialize New Project

Use this prompt after cloning the Agentic Development Starter as a template for a brand-new project. Provide your tech stack, project context, and goals — the agent will adapt all starter documentation to your project.

## How To Use

**In VS Code chat, type:**

```
Use initialize-new-project. My project is <project-name> — <one-line description>.
Tech stack: <frontend>, <backend>, <database>.
Goals: <goal 1>, <goal 2>, <goal 3>.
```

**Concrete example:**

```
Use initialize-new-project. My project is canteenmanagementsys — a cafeteria management system.
Tech stack: React frontend, FastAPI backend, PostgreSQL.
Goals: track menu items across locations, manage daily orders, monitor inventory levels.
```

The agent will read this prompt file for the full adaptation instructions, then rewrite README, reset changelogs, and trim stack overlays to match your stack.

## Context To Inspect First

- `README.md`, `CHANGELOG.md`, `DOC-CHANGELOG.md`, and any project-level docs.
- `.github/copilot-instructions.md` and `.github/instructions/`.
- `.github/starter-modules.json` to understand which modules are enabled.
- `docs/runbooks/starter-adoption.md` section 0 (Clone-As-Template).
- `docs/runbooks/starter-composition.md` for stack-specific overlay guidance.

## Deliverables

- Adapt the project name everywhere starter references appear (README title, doc references, changelog headers).
- Clear `README.md` of ALL starter content and write a fresh README for the project: project name and one-line purpose, tech stack, quick start, and links to the repo's real source-of-truth docs. No starter-specific sections, examples, or roadmap items may remain.
- Clear `CHANGELOG.md` completely for the new project: remove ALL existing starter entries (the starter's own development history never belongs to a downstream project). Keep only the "How To Use" header and the entry template, then add one template-compliant initial entry titled "Initialize project from Agentic Development Starter." (Change type: chore; Reason: project created from the starter via clone-as-template).
- Clear `DOC-CHANGELOG.md` the same way: remove ALL starter entries, keep only the header and entry template, then add one initial entry (Change type: docs) that cross-references the `CHANGELOG.md` initial entry.
- Remember the split: `CHANGELOG.md` is only for code changes made in THIS project; `DOC-CHANGELOG.md` is only for this project's documentation changes. Starter history must never remain in either log.
- Trim stack overlays that do not apply to the stated tech stack. Enable overlays that do apply.
- Keep all workflow assets intact: `.github/instructions/`, `.github/agents/`, `.github/skills/`, `.github/prompts/`, `.github/hooks/`, `.github/scripts/`, `.github/workflows/`, `docs/runbooks/`, `docs/adr/0000-template.md`, `evals/`.
- Leave `.github/copilot-instructions.md` unchanged — the baseline rules are project-agnostic.
- Confirm the chosen adoption mode (Minimal is the safe default for new projects).

## Safety Boundaries

- Do not delete or modify `.github/instructions/`, `.github/agents/`, `.github/skills/`, `.github/hooks/`, `.github/scripts/`, or `.github/workflows/` — these are workflow governance assets.
- Do not enable MCP servers, durable memory providers, or shell automation.
- Do not change `.github/copilot-instructions.md` baseline rules.
- Do not remove validation scripts or CI workflows.
- Do not leave starter changelog entries behind when initializing a new project.
- Stop and ask before destructive changes.

## Expected Output

- Cleared `README.md` of starter content with a fresh project README (name, purpose, tech stack, quick start).
- Cleared `CHANGELOG.md` (all starter entries removed) with a template-compliant initial entry.
- Cleared `DOC-CHANGELOG.md` (all starter entries removed) with a cross-referenced initial entry.
- Enabled/disabled overlays matching the stated tech stack.
- Confirmation of adoption mode.
- Suggested next steps (run validation, first commit, first agent chain).
