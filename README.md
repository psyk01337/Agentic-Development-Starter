# Agentic Development Starter (VS Code, June 2026 Workflow)

Agentic Development Starter is a repo-native workflow, safety, and governance starter for AI-assisted software development. It standardizes instructions, prompts, agents, skills, hooks, MCP templates, memory policy, handoffs, validation, and evaluation so teams can ship changes with consistent guardrails and auditability.

The starter is lightweight and composable. It is not a full agent runtime.

## Table of Contents

- [Quick Start](#quick-start)
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

1. Read `.github/copilot-instructions.md`.
2. Choose an adoption mode in `docs/runbooks/starter-adoption.md`.
3. Review `.github/starter-modules.json` to see core, optional, and overlay assets.
4. Keep MCP, durable memory, and high-risk automation disabled until reviewed.
5. Run starter validation before merging workflow changes.

Validation commands:

```bash
bash .github/scripts/check-starter-workflow.sh
```

```powershell
.github/scripts/check-starter-workflow.ps1
```

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

- `.github/copilot-instructions.md`: always-on repo baseline.
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
- `evals/`: checklist-driven golden-task harness.
- `CHANGELOG.md`: executable and behavior-affecting changes.
- `DOC-CHANGELOG.md`: documentation and workflow text changes.

## Core Vs Optional Modules

`.github/starter-modules.json` is the module source of truth.

Core modules cover baseline instructions, security, memory strategy, governance, agents, guardrails, validation, and CI.

Optional modules cover prompt workflows, skills, evals, editor templates, and MCP templates.

Overlay modules cover stack-specific guidance, Vitest TDD, approval-gated orchestration, Hermes runtime integration, and Honcho durable memory integration.

## Prompts

Prompt files are repeatable one-off tasks, not always-on rules. They live under `.github/prompts/` and include:

- Existing repo onboarding.
- Small feature planning.
- Small diff implementation.
- Current diff review.
- ADR creation.
- Test plan generation.
- Release note preparation.
- Starter migration planning.
- Security review.
- CI failure debugging.
- Problem structuring.

Each prompt states what context to inspect first, deliverables, safety boundaries, a destructive-change stop rule, and expected output.

## Skills

Skills are bounded multi-step playbooks. Use them when the workflow is repeatable and format-sensitive.

Included workflow skills cover ADR authoring, bug triage, PR review, QA test plans, security checks, release notes, session compaction, memory curation, repo onboarding, CI failure debugging, migration planning, tool-surface audits, and problem structuring.

Stack overlays include API and UI scaffold skills. Approval-gated handoffs are an optional overlay skill.

## Agents

The starter uses guided handoffs, not hidden automatic chains.

Core agents include analyst, tech planner, architecture reviewer, senior software engineer, code reviewer, security reviewer, QA, documentation maintainer, and process improvement. Vitest TDD and orchestration coordinator are overlays.

Each agent defines handoff memory, escalation behavior, required inputs, constraints, approach, and output format.

## Hooks And Guardrails

Hook policy lives in `.github/hooks/policy-rules.tsv` and is consumed by Bash and PowerShell pre-tool policy scripts.

Default blocks include destructive deletion, hard reset, checkout discard, force push, remote shell execution, `Invoke-Expression` from network content, recursive `chmod 777`, secret-like writes to `.env`, HTTP package registries, and explicitly unapproved core policy edits.

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

`evals/` contains manual/semi-automated golden tasks for checking whether agents follow starter rules. Initial tasks cover simple bugfixes, API endpoints, frontend components, security review, docs/changelog updates, CI debugging, and problem structuring.

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

1. Use `process-improvement` with explicit approval.
2. Update instructions, prompts, skills, agents, runbooks, or validators.
3. Update changelogs.
4. Run starter validation.

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
- MCP posture checks: `.github/scripts/check-mcp-posture.*`.
- Markdown checks: `.github/scripts/check-markdown-quality.*`.
- Eval harness checks: `.github/scripts/check-evals.*` or `evals/run-evals.*`.

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