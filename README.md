# Agentic Development Starter (VS Code, August 2026 Workflow)

Agentic Development Starter is a repo-native workflow, safety, and governance starter for AI-assisted software development. It standardizes instructions, prompts, agents, skills, hooks, MCP templates, memory policy, handoffs, validation, and evaluation so teams can ship changes with consistent guardrails and auditability.

The starter is lightweight and composable. It is not a full agent runtime.

## Table of Contents

- [Quick Start](#quick-start)
- [Start Here](#start-here)
- [How To Use This Repo Well](#how-to-use-this-repo-well)
- [How It Is Organized](#how-it-is-organized)
- [Use This When](#use-this-when)
- [Do Not Use This When](#do-not-use-this-when)
- [What This Is Not](#what-this-is-not)
- [Adoption Modes](#adoption-modes)
- [Folder Structure](#folder-structure)
- [Core Vs Optional Modules](#core-vs-optional-modules)
- [Prompts](#prompts)
- [Skills](#skills)
- [Agents](#agents)
- [Agentic Engine](#agentic-engine)
- [Hooks And Guardrails](#hooks-and-guardrails)
- [MCP Safety](#mcp-safety)
- [Memory Strategy](#memory-strategy)
- [Hermes And Honcho Integration](#hermes-and-honcho-integration)
- [Evaluation Harness](#evaluation-harness)
- [Recommended Workflow Examples](#recommended-workflow-examples)
- [Validation Commands](#validation-commands)
- [Security Defaults](#security-defaults)
- [Roadmap](#roadmap)

## How It Is Organized

The starter is split into:

- Core rules that apply in any repository.
- Optional overlays for specific stacks, runtimes, or workflows.
- Reusable agents and skills for planning, implementation, review, security, QA, documentation, release notes, migration, and process improvement.
- Hook-based guardrails and audit logging for destructive commands, risky package sources, secret-like writes, and unapproved policy edits.
- MCP and editor templates that stay disabled until reviewed.
- Validation and CI scripts that check manifests, prompts, skills, agents, hook policy, MCP posture, Markdown quality, and eval harness structure.
- Runbooks, ADRs, and changelogs that keep adoption decisions, workflow changes, and validation evidence traceable.

The core path is intentionally small: start with repo instructions, security defaults, memory policy, module manifest, changelogs, and validation. Add prompts, agents, skills, hooks, MCP templates, evals, and runtime overlays only when a repository needs that extra workflow surface and can review the risk.

## Use This When

- A team wants shared AI coding rules in the repository instead of hidden local preferences.
- Multiple agents or editors need the same safety posture and handoff format.
- You want prompts, skills, custom agents, hooks, CI checks, and runbooks to evolve together.
- You need starter governance that works across GitHub Copilot, VS Code agent mode, Copilot cloud agent, Claude Code, Codex, Cursor, OpenCode, and Hermes-style runtimes.

## Do Not Use This When

- You need a stateful runtime, scheduler, tool broker, or autonomous execution platform.
- You want to enable shell automation, MCP servers, browser automation, database access, or durable memory without review.
- You want a framework-specific app template instead of repo workflow governance.
- You cannot keep repo files as the source of truth.

## What This Is Not

This repository is not Hermes Agent. Hermes is a stateful runtime. This starter is the repo-level operating system for safe AI-assisted development: instructions, policies, prompts, skills, agents, handoffs, validation, and documentation. Hermes and Honcho are supported through optional overlays, not required by default.

## Quick Start

Start with [QUICKSTART.md](QUICKSTART.md) for the 10-minute path to a working app.

1. Clone the starter as your project root, detach the starter history, and run `git init`.
2. Drop any PRD, design brief, architecture note, API contract, or feature spec into `docs/inputs/`.
3. Run `route-project-inputs.prompt.md`. It classifies every file and runs `initialize-new-project`, `ingest-project-docs`, `build-feature`, or `improve-repo` in order. If you have no documents, run `initialize-new-project` directly.
4. Add application code under `app/`.
5. Run `build-feature.prompt.md` for the first vertical slice. For a multi-stage project, use `run-engineering-team.prompt.md` instead.
6. Run the starter validation and your application's own tests before merging.

For an existing app, use `docs/runbooks/adopting-existing-github.md` instead.

Keep MCP servers, durable memory, and high-risk automation disabled until reviewed. Do not keep improving the starter while building the app; use `improve-repo.prompt.md` only on real friction.

Validation commands:

```bash
bash .github/scripts/check-starter-workflow.sh
```

```powershell
pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1
```

## Start Here

Start with [QUICKSTART.md](QUICKSTART.md) for the fastest path to a working app, then read these six files in order before your first change:

1. `AGENTS.md` — the cross-agent entry point at the repository root; how the other agents find this repo's rules.
2. `.github/copilot-instructions.md` — the always-on baseline that every session inherits.
3. `.github/agent-catalog.md` — the specialist roles, the guided handoff contract, and the delegation triggers.
4. `docs/runbooks/agentic-dev.md` — the daily operating rhythm.
5. `docs/runbooks/starter-adoption.md` — how much of the starter to adopt.
6. `docs/runbooks/starter-composition.md` — what each module and overlay is for.

After that, use the [Runbooks Index](docs/runbooks/INDEX.md) to find guidance by task, and `.github/starter-modules.json` as the authoritative inventory of what ships enabled.

## How To Use This Repo Well

The starter earns its keep only when the repo stays the source of truth and the workflow runs as a loop rather than a one-off prompt. These habits are what make it pay off.

### 1. Run every task as a loop

1. **Frame.** If you dropped one or more planning documents in `docs/inputs/`, run `route-project-inputs.prompt.md`; it classifies every file and routes it to `initialize-new-project`, `ingest-project-docs`, `build-feature`, or `improve-repo`. For a multi-stage project, use `run-engineering-team.prompt.md`; the supervisor builds a task board and assigns approved specialists by squad. Write work can run through `agentic_engine.py`, which loops implement → verify → repair until verified or escalates on a repeated failure or exhausted attempt budget. If the problem is vague or spans systems, use the `problem-structuring` skill, then `analyst`.
2. **Route.** Choose the smallest surface that fits the task, using the surface table below.
3. **Deliver.** Use `build-feature.prompt.md` for one feature end-to-end, or invoke `senior-software-engineer` directly; use `tdd-vitest` only in repos that actually run Vitest.
4. **Verify.** Run the smallest relevant validation. Add `code-reviewer` and `qa` for anything user-facing, and `security-reviewer` when the change touches secrets, auth, command execution, hooks, MCP, memory, or dependency trust.
5. **Record.** `CHANGELOG.md` for executable behavior, `DOC-CHANGELOG.md` for docs, and an ADR for durable decisions.
6. **Validate.** Workflow-asset edits are not finished until the starter checks pass.
7. **Hand off.** Every agent ends with `Decision status`, `Recommended next agent`, `Why that next agent`, `Inputs for next agent`, and `Blockers or approvals needed`.

Chains and conditional redirects are listed in `.github/agent-catalog.md` and walked through in `docs/runbooks/agentic-dev.md`.

### 2. Pick the right surface for the job

| You have... | Use a... | It lives in |
| --- | --- | --- |
| A harness that needs one entry point | Cross-agent entry | `AGENTS.md` (repo root) |
| A rule that must apply to every session | Instruction | `.github/instructions/` |
| A repeatable one-off task | Prompt | `.github/prompts/` |
| A bounded, format-sensitive playbook | Skill | `.github/skills/` |
| A recurring role that needs judgment | Agent | `.github/agents/` |
| A durable decision with tradeoffs | ADR | `docs/adr/` |
| An operational procedure | Runbook | `docs/runbooks/` |
| A shell command that should be blocked | Hook rule | `.github/hooks/policy-rules.tsv` |

Promote upward only when a pattern proves itself: a prompt that keeps being reused becomes a skill, a skill that keeps needing judgment becomes an agent, and a rule that must never be forgotten becomes an instruction.

### 3. Choose the smallest adoption mode that works

| Your situation | Start with |
| --- | --- |
| Solo work on a small repo | Minimal Install |
| Multiple contributors or agents sharing workflows | Team Mode |
| Review gates, eval harness, or MCP templates after review | Advanced Mode |
| Org-wide policy, audit, and approval records | Enterprise Mode |

Add a mode's assets only when the team can review the risk, and keep MCP servers, durable memory, and high-risk automation disabled until that review happens.

### 4. Keep repo truth authoritative

- Repo files outrank session memory, chat history, and personal preference. A decision that only exists in a chat is not yet repo truth.
- Never put secrets, credentials, tokens, customer data, or production logs in repo files, logs, fixtures, or memory.
- Cross-reference `CHANGELOG.md` and `DOC-CHANGELOG.md` entries when code and docs move together, and record known drift explicitly instead of leaving it implicit.

### 5. Keep the checks green

- Umbrella check after any workflow-asset edit: `bash .github/scripts/check-starter-workflow.sh` or `.github/scripts/check-starter-workflow.ps1`.
- Single-purpose checks: `make markdown`, `make hooks`, `make skills`, `make agents`, `make prompts`, `make mcp`, and `make evals`.
- Treat a red check as a blocker, not a warning. CI runs the same contracts on push and pull request.

### 6. Extend it deliberately

1. Add the file in the surface directory that matches the table above.
2. Register it in `.github/starter-modules.json`, or the manifest check fails.
3. For an agent, also register it in `.github/agent-catalog.md` and `.github/roles/tool-access.json` (`agentRoleHints` plus `agentCapabilityMatrix`), and include a `## Handoff Memory Contract` section.
4. For a skill, give `SKILL.md` frontmatter a lowercase hyphenated `name` and a `description`.
5. For a prompt, state the context to inspect first, deliverables, safety boundaries, a destructive-change stop rule, and the expected output.
6. Add an eval task and matching checklist under `evals/` when the workflow should be behavior-tested.
7. Update both changelogs and run the umbrella check.

### 7. Avoid these common mistakes

- Copying the starter's example docs into a project instead of pointing at the repo's real source-of-truth docs.
- Enabling an overlay before its code path exists, such as game overlays in a repo with no `app/game/`.
- Letting a prompt file quietly become an always-on rule; durable standards belong in instructions.
- Editing policy inside the hook scripts instead of `.github/hooks/policy-rules.tsv`.
- Trusting chat memory for decisions that belong in an ADR or runbook.
- Skipping the changelog because the change "was small".

## Adoption Modes

### Minimal Install

Use for a small repo or first rollout:

- Core Copilot instructions.
- Core and security overlays.
- Memory strategy baseline.
- Module manifest.
- Basic validation scripts.
- Changelogs.

### Team Mode

Use when multiple contributors or agents need shared workflows:

- Agents.
- Skills.
- Prompt files.
- Hook policy.
- CI validation.
- Starter runbooks.

### Advanced Mode

Use when the team needs stronger governance:

- Approval-gated handoff overlay.
- MCP templates after review.
- Eval harness.
- Tool-surface matrix.
- Memory policy and optional examples.

### Enterprise Mode

Use when organization-level governance matters:

- Org instruction overlays.
- Private shared skills.
- Centralized policy review.
- Security and audit requirements.
- Periodic evals across supported agents.

## Folder Structure

- `AGENTS.md`: cross-agent entry point at the repository root; routes other harnesses to the scoped rules.
- `.github/copilot-instructions.md`: always-on repo baseline.
- `.github/agent-catalog.md`: agent roster, handoff contract, and delegation triggers.
- `.github/instructions/`: core, stack, memory, and optional runtime overlays.
- `.github/prompts/`: reusable slash-command style task prompts.
- `.github/agents/`: specialist agent definitions.
- `.github/skills/`: reusable multi-step workflow playbooks.
- `.github/hooks/`: deterministic policy rules and hook scripts.
- `.github/scripts/`: starter validation scripts.
- `.github/workflows/`: CI checks for starter consistency.
- `.github/examples/`: disabled examples for overlays and integrations.
- `.vscode/mcp.json`: disabled MCP template catalog.
- `docs/adr/`: durable architecture and workflow decisions.
- `docs/runbooks/`: operational guidance.
- `docs/inputs.md`: source-document provenance, routing log, and supported formats.
- `.agentic/state/`: task-scoped engine state, gitignored and never committed.
- `evals/`: checklist-driven golden-task harness.
- `CHANGELOG.md`: executable and behavior-affecting changes.
- `DOC-CHANGELOG.md`: documentation and workflow text changes.

## Core Vs Optional Modules

`.github/starter-modules.json` is the module source of truth.

Core modules cover baseline instructions, security, memory strategy, governance, agents, guardrails, validation, and CI. `.github/copilot-instructions.md` and the `core`, `security`, and `memory` instruction files load on every request; other overlays load only when a matching file is in context. See `docs/runbooks/starter-composition.md` for the loading model.

Optional modules cover prompt workflows, skills, evals, editor templates, and MCP templates.

Overlay modules cover stack- and domain-specific guidance (frontend, backend, PHP/Laravel ecosystem, database, CI workflow, embedded, reverse engineering, networking, and game development overlays), Vitest TDD, approval-gated orchestration, supervisor orchestration, Hermes runtime integration, and Honcho durable memory integration.

## Prompts

Prompt files are repeatable one-off tasks, not always-on rules. They live under `.github/prompts/` and include:

- Existing repo onboarding.
- End-to-end feature delivery through plan, implementation, review, and QA.
- Project input routing for one or more dropped Markdown files (`route-project-inputs.prompt.md`).
- Engineering-team orchestration for full SDLC delivery (`run-engineering-team.prompt.md`, supervisor overlay).
- Deterministic implement-verify-repair loop with bounded retries (`.github/scripts/agentic_engine.py`, `repair-loop` skill).
- Project document ingestion for PRDs, design briefs, architecture notes, and API contracts (`ingest-project-docs.prompt.md`, run in the downstream project repo).
- Small feature planning.
- Small diff implementation.
- Bug fixing with hypothesis and regression test.
- Current diff review.
- ADR creation.
- Test plan generation.
- Release note preparation.
- Starter migration planning.
- Security review.
- CI failure debugging.
- Problem structuring.
- Hook policy rule updates.
- Repo self-improvement loop (one bounded iteration at a time).
- Game system design, mechanic implementation, performance profiling, and build preparation.

Each prompt states what context to inspect first, deliverables, safety boundaries, a destructive-change stop rule, and expected output.

## Skills

Skills are bounded multi-step playbooks. Use them when the workflow is repeatable and format-sensitive.

Included workflow skills cover ADR authoring, bug triage, PR review, QA test plans, security checks, threat modeling, database migrations, dependency upgrades, safe refactors, release notes, session compaction, memory curation, repo onboarding, CI failure debugging, migration planning, tool-surface audits, and problem structuring.

Stack overlays include API and UI scaffold skills, plus `game-perf-triage` for game frame-time, memory, and load-time diagnosis. Domain skills include `embedded-bringup`, `binary-analysis` for authorized reverse engineering, `network-troubleshooting`, `web-quality`, and `game-design`. Approval-gated handoffs are an optional overlay skill.

## Agents

The starter uses guided handoffs, not hidden automatic chains.

Core agents include analyst, tech planner, architecture reviewer, senior software engineer, code reviewer, security reviewer, QA, documentation maintainer, and process improvement. Vitest TDD, the orchestration coordinator, and the delegation supervisor are overlays. The delegation supervisor is opt-in and distinct from the orchestration coordinator: the coordinator governs human-guided and approval-gated transitions, while the supervisor governs supervised machine delegation of bounded tasks to allow-listed agents.

Each agent defines handoff memory, escalation behavior, required inputs, constraints, approach, and output format.

## Agentic Engine

`agentic_engine.py` is the optional deterministic control plane for multi-step delivery. The host agent does the work; the engine decides whether to continue, repair, or escalate.

```text
init -> approval? -> implement -> verify
                                  |-- VERIFIED -> review -> done
                                  |-- NOT_VERIFIED -> repair -> verify
                                  `-- repeated failure or budget -> blocked
```

It enforces a declared write set, evidence at every stage, passing checks for `VERIFIED`, reviewer separation, bounded repair attempts, identical-failure detection, and approval gates. State is task-scoped under `.agentic/state/` and gitignored. Requires Python 3.9+.

```bash
python .github/scripts/agentic_engine.py selftest
python .github/scripts/agentic_engine.py next --run-id <run-id>
```

See `docs/runbooks/agentic-engine.md` for the stage contract and blocker reasons, and `TROUBLESHOOTING.md` when a run is blocked.
## Hooks And Guardrails

Hook policy lives in `.github/hooks/policy-rules.tsv` and is consumed by Bash and PowerShell pre-tool policy scripts.

Default blocks include destructive deletion, hard reset, checkout discard, force push, remote shell execution, `Invoke-Expression` from network content, recursive `chmod 777`, secret-like writes to `.env`, app signing keystores and provisioning profiles, `git lfs migrate` history rewrites, forced LFS prune, HTTP package registries, and explicitly unapproved core policy edits.

Hook policy tests live in `.github/scripts/check-hook-policy.*` and run in CI.

## MCP Safety

`.vscode/mcp.json` is a template catalog. All servers and apps remain disabled by default.

Templates include repo context, local automation, browser automation, GitHub, database, and file-system MCP shapes. Each high-risk template documents purpose, required permissions, and risks.

Before enabling any MCP server, use the approval checklist in `docs/runbooks/mcp-servers.md`.

## Memory Strategy

Memory uses three layers:

1. Session and handoff memory for current task state.
2. Repo truth for durable decisions, standards, contracts, runbooks, and changelogs.
3. Optional durable memory for stable non-sensitive preferences and repeated patterns.

Never store secrets, credentials, customer private data, production logs, or regulated data in agent memory.

Use `docs/runbooks/memory-strategy.md` and `.github/instructions/memory.instructions.md` as the default memory policy.

## Hermes And Honcho Integration

Hermes is supported as an optional runtime overlay. It should read repo truth, honor hook policies, preserve handoff contracts, and avoid self-modifying core workflow files without approval.

Honcho is supported as an optional durable memory overlay. It must stay scoped, explicit, reviewable, and subordinate to repo truth.

Both overlays are disabled by default and documented in `docs/runbooks/hermes-runtime.md` and `docs/runbooks/honcho-memory.md`.

## Evaluation Harness

`evals/` contains manual/semi-automated golden tasks for checking whether agents follow starter rules. Initial tasks cover simple bugfixes, API endpoints, frontend components, Laravel components, gameplay mechanics, game performance triage, security review, docs/changelog updates, CI debugging, problem structuring, document ingestion, and decision trails.

Structure checks:

```bash
bash evals/run-evals.sh
```

```powershell
evals/run-evals.ps1
```

## Recommended Workflow Examples

Simple fix:

1. Use `implement-small-diff.prompt.md` or `senior-software-engineer`.
2. Run focused validation.
3. Use `review-current-diff.prompt.md` or `code-reviewer`.

Security-sensitive change:

1. Use `security-review.prompt.md` or `security-reviewer`.
2. Fix findings with `senior-software-engineer`.
3. Re-run hook, policy, and focused tests.

Unstructured problem:

1. Use `structure-technical-problem.prompt.md` or the `problem-structuring` skill.
2. Hand off to `analyst` for evidence gathering.
3. Hand off to `tech-planner` for design and phased planning.

Workflow improvement:

1. Use `process-improvement` with explicit approval, or run `improve-repo.prompt.md` for one bounded iteration.
2. Update instructions, prompts, skills, agents, runbooks, or validators.
3. Update changelogs.
4. Run starter validation.
5. Follow `docs/runbooks/self-improvement.md` for the loop contract and stop conditions.

Existing repo adoption:

1. Use `onboard-existing-repo.prompt.md`.
2. Choose an adoption mode.
3. Merge minimal baseline first.
4. Add team or advanced modules in small follow-up changes.

## Validation Commands

- Umbrella checks: `.github/scripts/check-starter-workflow.sh` and `.github/scripts/check-starter-workflow.ps1`.
- Manifest checks: `.github/scripts/check-starter-manifest.*`.
- Skill checks: `.github/scripts/check-starter-skills.*`.
- Agent checks: `.github/scripts/check-agent-contracts.*`.
- Prompt checks: `.github/scripts/check-prompt-contracts.*`.
- Hook policy checks: `.github/scripts/check-hook-policy.*`.
- Supervisor orchestration checks: `.github/scripts/check-supervisor-orchestration.*`.
- MCP posture checks: `.github/scripts/check-mcp-posture.*`.
- Markdown checks: `.github/scripts/check-markdown-quality.*`.
- Eval harness checks: `.github/scripts/check-evals.*` or `evals/run-evals.*`.
- Agentic engine checks: `.github/scripts/check-agentic-engine.*` and `python .github/scripts/agentic_engine.py selftest`.

`Makefile` wraps the most common runs: `make validate` (umbrella, Bash), `make validate-ps` (umbrella, PowerShell), `make check-all` (every individual check including Markdown quality), and the single-purpose targets `make markdown`, `make hooks`, `make skills`, `make agents`, `make prompts`, `make mcp`, and `make evals`.

CI runs the same contracts through `.github/workflows/validation.yml` and `.github/workflows/skill-contract-tests.yml` on push and pull request, so a local pass and a green PR check validate the same expectations.

## Security Defaults

- No secrets in repo files, examples, logs, prompts, or memory.
- No MCP servers enabled by default.
- No durable memory providers enabled by default.
- No dangerous shell automation enabled by default.
- Hook policy blocks common destructive and supply-chain-risky commands.
- CI validates starter contracts on push and pull request.

## Roadmap

- Add machine-readable eval scoring metadata.
- Add fixture repositories for controlled golden tasks.
- Add optional platform adapters for non-VS Code agents.
- Expand policy fixtures as real false positives and bypass cases are discovered.
- Add deeper schema validation for prompt and agent metadata when platform contracts stabilize.