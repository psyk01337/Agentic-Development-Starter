# Quick Start Guide

Get from a clean checkout to your first application feature in about 10 minutes.

This starter is a workflow layer, not an application template. Use it one of two ways:

- **New app:** clone the starter as your project root and add code under `app/`.
- **Existing app:** copy the workflow assets into the existing repository.

## Prerequisites

- Git
- VS Code with GitHub Copilot agent mode
- Bash (Linux/macOS/WSL) or PowerShell (Windows)
- Python 3.9 or newer for the optional agentic engine

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

### 2. Drop your planning documents (optional but recommended)

Create the directory and place any PRD, design brief, architecture note, API contract, or feature spec there. Markdown and plain text are preferred; convert PDF or DOCX first. If you have no documents, skip to step 3.

PowerShell:

```powershell
New-Item -ItemType Directory -Path docs/inputs -Force
```

Bash:

```bash
mkdir -p docs/inputs
```

### 3. Run the intake router

Open the repository in VS Code and say:

```text
Use route-project-inputs. I dropped these Markdown files in docs/inputs/.
Classify each, write the routing table, and run the right workflows in order.
```

The router runs `initialize-new-project` once if the project context is still generic, then `ingest-project-docs` for repo-truth documents, `build-feature` for one bounded feature spec, and `improve-repo` only for workflow documents. It defers incomplete or unreadable files.

If you have no planning documents, run the initialization prompt directly:

```text
Use initialize-new-project. My project is <name> — <description>.
Tech stack: <frontend>, <backend>, <database>.
Goals: <goal 1>, <goal 2>, <goal 3>.
```

If you want a rollback point, commit the untouched starter before running either prompt.

**For a multi-stage project:** use `run-engineering-team.prompt.md`. The supervisor builds a task board and assigns approved discovery, architecture, implementation, review, QA, security, and documentation specialists while keeping one delegation level. This requires the supervisor overlay; if it is disabled, the prompt produces a guided plan instead.

### 4. Create the application directory

PowerShell:

```powershell
New-Item -ItemType Directory -Path app -Force
```

Bash:

```bash
mkdir -p app
```

Add frontend and backend code under `app/`. The starter does not enforce a specific layout.

### 5. Build the first vertical slice

```text
Use build-feature. Build <one small end-to-end feature>.
Acceptance criteria: <...>.
Out of scope: <...>.
```

The prompt routes the work through plan, implementation, tests, `code-reviewer`, `qa`, and changelog updates. Start with one endpoint or one screen, not a subsystem.

### 6. Validate

```bash
bash .github/scripts/check-starter-workflow.sh
```

```powershell
pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1
```

Also run the application's own test, lint, and build commands.

### 7. Commit

```bash
git add -A
git commit -m "Initialize project from Agentic Development Starter"
```

## Path B — Existing App

1. Read `docs/runbooks/adopting-existing-github.md`.
2. Copy the baseline first: `.github/copilot-instructions.md`, `.github/instructions/core.instructions.md`, `.github/instructions/security.instructions.md`, `.github/starter-modules.json`, `CHANGELOG.md`, `DOC-CHANGELOG.md`, and `docs/inputs.md`.
3. Add agents, skills, prompts, and hooks in a follow-up commit.
4. Run the umbrella checks.
5. Drop existing PRD, design, architecture, or API documents in `docs/inputs/` and run `route-project-inputs.prompt.md` before implementation.
6. Use `build-feature.prompt.md` for the first feature.

## Choose Team Mode

Use Team Mode for application development: core instructions, agents, skills, prompts, hooks, and CI. Skip Advanced and Enterprise until you need evals or organization-wide governance. Keep MCP servers, durable memory, and the supervisor and approval overlays disabled by default.

## The Daily Loop

1. Use `run-engineering-team.prompt.md` for multi-stage work, or `build-feature.prompt.md` for one feature.
2. For work that may need more than one fix attempt, run it through `.github/scripts/agentic_engine.py`. It loops implement → verify → repair until verified, stops on a repeated identical failure, and escalates when the attempt budget is exhausted.
3. If the engine reports a blocked run, stop and escalate the blocker packet. Do not retry manually or raise the attempt limit to force a pass; see `TROUBLESHOOTING.md`.
4. Review the diff with `code-reviewer`.
5. Verify with `qa`.
6. Update `CHANGELOG.md` and `DOC-CHANGELOG.md`.
7. Commit a small, reviewable change.

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
- `docs/runbooks/agentic-engine.md` — engine stages, evidence rules, and blocker reasons.
- `TROUBLESHOOTING.md` — common issues and fixes, including blocked engine runs and Git push authentication.
