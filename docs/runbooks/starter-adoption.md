# Starter Adoption Runbook

Use this runbook to choose a safe adoption path for a new or existing repository.

## 0. Clone-As-Template (New Project Quickstart)

Use this path when starting a brand-new project from scratch. Instead of copying `.github/` into a separate repo, clone the starter directly and rename it as your project root.

### Steps

1. **Clone and rename:**
   ```bash
   git clone https://github.com/psyk01337/Agentic-Development-Starter.git my-project
   cd my-project
   ```

2. **Detach from the starter's git history** and reinitialize for your project:
   ```bash
   rm -rf .git
   git init
   ```

3. **Clean up starter-specific artifacts** you don't need:
   - `MIGRATION.md` — migration guide for v1.0→v1.1 upgrades; safe to remove for new projects.
   - `checklist.md` — local-only checklist (already gitignored); safe to remove.
   - `CHANGELOG.md` and `DOC-CHANGELOG.md` — reset to empty logs for your project, or keep the templates and clear the entries.
   - `README.md` — replace the starter README with your project's README.

4. **Add your application code** alongside the workflow assets:
   ```bash
   mkdir -p app
   ```
   The `app/` directory is the recommended home for your frontend and backend code, keeping application source separate from the workflow governance layer in `.github/`, `docs/`, and `evals/`. Typical layouts:

   **Multi-stack:**
   ```
   app/frontend/   # React, Next.js, Vue, etc.
   app/backend/    # FastAPI, Express, etc.
   ```

   **Single-stack:**
   ```
   app/src/        # your application source
   app/tests/      # your application tests
   ```

   You own the `app/` convention — rename it to `src/`, `services/`, or whatever fits your project. The starter does not enforce a specific application directory name.

5. **Choose an adoption mode** below (start with Minimal), then commit:
   ```bash
   git add -A
   git commit -m "Initialize project with Agentic Development Starter (Minimal mode)"
   ```

6. **Run the initialization prompt** to adapt all starter documentation to your project. After the first commit, invoke the `initialize-new-project` prompt with your tech stack, project context, and goals. The agent will:
   - Rewrite `README.md` for your project (purpose, tech stack, quick start).
   - Reset `CHANGELOG.md` and `DOC-CHANGELOG.md` to empty logs with an initial entry.
   - Enable stack overlays that match your tech stack and disable those that don't.
   - Keep all workflow governance assets intact (instructions, agents, skills, hooks, scripts, CI).

   Example first prompt:
   > Use initialize-new-project. My project is canteenmanagementsys — a cafeteria management system. Tech stack: React frontend, FastAPI backend, PostgreSQL. Goals: track menu items, orders, and inventory across multiple cafeteria locations.

   The prompt file lives at `.github/prompts/initialize-new-project.prompt.md` and can be reused whenever you start a new project from this starter.

### When To Use This Path

| Clone-as-template | Copy `.github/` into existing repo |
|---|---|
| Brand-new project, no existing code | Existing repo with its own `.github/` |
| You want the full starter structure as your project skeleton | You only need the workflow governance layer |
| You'll build app code inside this repo | App code already lives elsewhere |

If you're adding the starter to an existing repository, skip this section and use `docs/runbooks/adopting-existing-github.md` instead.

## 1. Minimal Mode

Use when a repo only needs baseline AI coding guardrails.

Include:

- `.github/copilot-instructions.md`
- `.github/instructions/core.instructions.md`
- `.github/instructions/security.instructions.md`
- `.github/starter-modules.json`
- Basic validation scripts
- `CHANGELOG.md` and `DOC-CHANGELOG.md`

Keep disabled:

- MCP servers
- Approval-gated orchestration
- Durable memory providers
- Runtime overlays

Validation:

- Run `.github/scripts/check-starter-workflow.sh` or `.github/scripts/check-starter-workflow.ps1`.

## 2. Team Mode

Use when multiple contributors or agents need shared workflow assets.

Add:

- `.github/AGENTS.md`
- `.github/agents/*.agent.md`
- `.github/skills/*/SKILL.md`
- `.github/prompts/*.prompt.md`
- Hook policy templates
- CI validation workflows

Validation:

- Run starter workflow checks.
- Run hook policy checks.
- Run skill and prompt contract checks.

## 3. Advanced Mode

Use when a team needs stronger governance and repeatable agent behavior testing.

Add:

- Approval-gated handoff overlay
- MCP templates after approval
- Eval harness
- Memory policy and optional memory examples
- Tool-surface compatibility matrix

Keep default-disabled until reviewed:

- MCP servers
- Browser automation
- Database access
- Durable memory
- Shell automation beyond normal validation commands

Validation:

- Run all starter checks.
- Run eval harness structure checks.
- Review MCP approval checklist before enabling tools.

## 4. Enterprise Mode

Use when organization-wide governance, audit, and policy consistency matter.

Add or adapt:

- Org-level instruction overlays.
- Private shared skills and prompts.
- Centralized policy review.
- Security review requirements.
- Audit expectations for hooks, CI, handoffs, and memory.
- Approval records for high-risk automation.

Validation:

- Require CI checks on every pull request.
- Require security review for changes to hooks, MCP, memory, auth, secrets, and command execution.
- Periodically run eval tasks against supported agent platforms.

## Adoption Rules

- Start with the smallest mode that solves the team's current problem.
- Preserve existing repo-specific rules unless there is explicit approval to replace them.
- Keep optional overlays composable and default-disabled.
- Record durable workflow decisions in ADRs or runbooks.
- Update changelogs when starter behavior or docs change.