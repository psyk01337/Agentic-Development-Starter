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
- Rewrite `README.md` for the specific project — replace the starter description with the project's purpose, tech stack, and quick start.
- Reset `CHANGELOG.md` to an empty log (keep the header and entry template, remove all starter entries). Add an initial entry: "Initialize project from Agentic Development Starter."
- Reset `DOC-CHANGELOG.md` to an empty log (keep the header and entry template, remove all starter entries). Add an initial entry cross-referencing the CHANGELOG entry.
- Trim stack overlays that do not apply to the stated tech stack. Enable overlays that do apply.
- Keep all workflow assets intact: `.github/instructions/`, `.github/agents/`, `.github/skills/`, `.github/prompts/`, `.github/hooks/`, `.github/scripts/`, `.github/workflows/`, `docs/runbooks/`, `docs/adr/0000-template.md`, `evals/`.
- Leave `.github/copilot-instructions.md` unchanged — the baseline rules are project-agnostic.
- Confirm the chosen adoption mode (Minimal is the safe default for new projects).

## Safety Boundaries

- Do not delete or modify `.github/instructions/`, `.github/agents/`, `.github/skills/`, `.github/hooks/`, `.github/scripts/`, or `.github/workflows/` — these are workflow governance assets.
- Do not enable MCP servers, durable memory providers, or shell automation.
- Do not change `.github/copilot-instructions.md` baseline rules.
- Do not remove validation scripts or CI workflows.
- Stop and ask before destructive changes.

## Expected Output

- Updated `README.md` with project name, description, tech stack, and quick start.
- Reset `CHANGELOG.md` with initial entry.
- Reset `DOC-CHANGELOG.md` with initial entry.
- Enabled/disabled overlays matching the stated tech stack.
- Confirmation of adoption mode.
- Suggested next steps (run validation, first commit, first agent chain).
