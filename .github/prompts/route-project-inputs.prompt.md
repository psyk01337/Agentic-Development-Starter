# Route Project Inputs

Use this prompt when the user drops one or more Markdown files into `docs/inputs/` and wants them assessed and routed without choosing a workflow file by file.

## Context To Inspect First

- Every new or changed Markdown file under `docs/inputs/`, plus any attached files. Process all of them in one pass.
- `docs/inputs.md` for the workflow destinations, supported formats, provenance, and routing log.
- The four destination prompts: `.github/prompts/initialize-new-project.prompt.md`, `.github/prompts/ingest-project-docs.prompt.md`, `.github/prompts/build-feature.prompt.md`, and `.github/prompts/improve-repo.prompt.md`.
- The current repository state: `README.md`, the `docs/` tree, `.github/starter-modules.json`, existing PRD/architecture/API docs, and application code.
- `docs/runbooks/agentic-dev.md` and `docs/runbooks/self-improvement.md`.

## Deliverables

- Inventory every dropped file with its path, detected type, confidence, and provenance.
- Classify each file into exactly one primary destination:
  - `initialize-new-project` for a project brief that supplies the name, purpose, stack, goals, constraints, or adoption mode when the repository still has generic starter context.
  - `ingest-project-docs` for a PRD, design brief, architecture note, API contract, requirements, or research document that should become repo truth.
  - `build-feature` for a bounded feature specification with acceptance criteria and enough detail for one vertical slice.
  - `improve-repo` for a document about the starter or workflow itself: process friction, validation gaps, or agent, skill, and prompt improvements.
  - `defer` for incomplete, unreadable, or ambiguous inputs; list the missing information.
- Write a routing table in `docs/inputs.md` (create it from the starter template if missing) with source file, type, confidence, target workflow, reason, execution order, and status.
- Execute the destinations in this order without asking the user to choose file by file:
  1. `initialize-new-project` once, only if the project context is still generic.
  2. `ingest-project-docs` for all repo-truth documents before any feature work.
  3. `build-feature` only for one bounded specification; queue any additional feature specs for later invocations.
  4. `improve-repo` separately and only for workflow documents, one bounded iteration.
- Update provenance and the routing log in `docs/inputs.md`.
- Update `DOC-CHANGELOG.md` for documentation and `CHANGELOG.md` only for executable or configuration changes.
- Report what was executed, what was deferred, and the next action.

## Safety Boundaries

- Confirm the target is a downstream project repository, not the starter template. Do not overwrite the starter's `README.md` or `docs/ARCHITECTURE.md` without explicit approval.
- Do not run `build-feature` directly on a PRD, design, or API document. Ingest it first.
- Do not run `initialize-new-project` on an already initialized project unless the user explicitly asks to reset project context.
- Do not run `improve-repo` on product documents; it is only for repository workflow improvements.
- Do not invent requirements or silently resolve conflicts between sources. Record the conflict and stop when it affects architecture, security, scope, cost, or irreversible behavior.
- Do not execute more than one `improve-repo` iteration per invocation.
- Stop and ask before destructive changes, broad rewrites, dependency changes, security-sensitive changes, or enabling MCP servers, durable memory, or high-risk automation.
- Keep secrets, customer data, and confidential content out of logs, examples, and generated docs.
- If a file is unreadable or unsupported, mark it `defer` and ask for a converted copy.

## Expected Output

- Inventory and routing table
- Files created or updated
- Workflows executed and their evidence
- Deferred files and missing inputs
- Provenance and changelog locations
- Recommended next action and approval needed
