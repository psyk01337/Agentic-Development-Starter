# Quick Start Guide

Get from a clean checkout to your first application feature in about 10 minutes.

This starter is a workflow layer, not an application template. Use it one of two ways:

- **New app:** clone the starter as your project root and add code under `app/`.
- **Existing app:** copy the workflow assets into the existing repository.

## Prerequisites

- Git
- VS Code with GitHub Copilot agent mode
- Bash (Linux/macOS/WSL) or PowerShell (Windows)

## Path A — New App (Recommended)

### 1. Clone the starter as your project

PowerShell:

```powershell
git clone https://github.com/psyk01337/Agentic-Development-Starter.git my-app
Set-Location my-app
Remove-Item -Recurse -Force .git
git init
```

Bash:

```bash
git clone https://github.com/psyk01337/Agentic-Development-Starter.git my-app
cd my-app
rm -rf .git
git init
```

If you have local starter changes, clone your local path or commit and push them first.

### 2. Initialize the project

Open the repository in VS Code and run:

```text
Use initialize-new-project. My project is <name> — <description>.
Tech stack: <frontend>, <backend>, <database>.
Goals: <goal 1>, <goal 2>, <goal 3>.
```

If you want a rollback point, commit the untouched starter before running the prompt. The prompt rewrites the project README, resets both changelogs, and trims stack overlays to match your stack. Keep the workflow assets intact.

**If you have a PRD, design brief, architecture note, or API contract:** place it in `docs/inputs/` (create the directory if needed) or attach it, record provenance in `docs/inputs.md`, then run `ingest-project-docs.prompt.md` before coding. It turns the document into `docs/prd.md`, `docs/architecture.md`, `docs/api.md` (as applicable), and a gap analysis without inventing missing requirements.

### 3. Create the application directory

PowerShell:

```powershell
New-Item -ItemType Directory -Path app -Force
```

Bash:

```bash
mkdir -p app
```

Add frontend and backend code under `app/`. The starter does not enforce a specific layout.

### 4. Build the first vertical slice

```text
Use build-feature. Build <one small end-to-end feature>.
Acceptance criteria: <...>.
Out of scope: <...>.
```

The prompt routes the work through plan, implementation, tests, `code-reviewer`, `qa`, and changelog updates. Start with one endpoint or one screen, not a subsystem.

### 5. Validate

```bash
bash .github/scripts/check-starter-workflow.sh
```

```powershell
pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1
```

Also run the application's own test, lint, and build commands.

### 6. Commit

```bash
git add -A
git commit -m "Initialize project from Agentic Development Starter"
```

## Path B — Existing App

1. Read `docs/runbooks/adopting-existing-github.md`.
2. Copy the baseline first: `.github/copilot-instructions.md`, `.github/instructions/core.instructions.md`, `.github/instructions/security.instructions.md`, `.github/starter-modules.json`, `CHANGELOG.md`, `DOC-CHANGELOG.md`, and `docs/inputs.md`.
3. Add agents, skills, prompts, and hooks in a follow-up commit.
4. Run the umbrella checks.
5. Run `ingest-project-docs.prompt.md` on existing PRD, design, architecture, or API documents before implementation.
6. Use `build-feature.prompt.md` for the first feature.

## Choose Team Mode

Use Team Mode for application development: core instructions, agents, skills, prompts, hooks, and CI. Skip Advanced and Enterprise until you need evals or organization-wide governance. Keep MCP servers, durable memory, and the supervisor and approval overlays disabled by default.

## The Daily Loop

1. Use `build-feature.prompt.md` for one feature.
2. Review the diff with `code-reviewer`.
3. Verify with `qa`.
4. Update `CHANGELOG.md` and `DOC-CHANGELOG.md`.
5. Commit a small, reviewable change.

## Keep the Framework Frozen

Do not keep improving the starter while you are building the application. Use `improve-repo.prompt.md` only when a real friction point appears; it runs one bounded iteration and stops at the approval boundary.

## Common Tasks

### Plan a feature

Use `build-feature.prompt.md` or `plan-small-feature.prompt.md`.

### Implement a small change

Use `build-feature.prompt.md` or `implement-small-diff.prompt.md`.

### Review code

Use `review-current-diff.prompt.md` or `code-reviewer`.

### Create an ADR

Use `create-adr.prompt.md` or `architecture-reviewer`.

## Need Help?

- `docs/runbooks/starter-adoption.md` — adoption modes and the clone-as-template details.
- `docs/runbooks/agentic-dev.md` — daily workflow and guided handoff chains.
- `docs/runbooks/self-improvement.md` — bounded repository improvement loop.
- `TROUBLESHOOTING.md` — common issues and fixes.
