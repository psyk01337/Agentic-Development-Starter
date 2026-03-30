# Agentic Development Starter (VS Code, Feb 2026 Workflow)

This repository is a modular starter for repo-shared agent workflows. It is designed to be composed, not copied wholesale around one language, framework, or test runner.

The starter is split into:

- Core rules that apply in any repository
- Optional overlays for specific stacks or workflows
- Reusable agents and skills
- Hook-based guardrails and audit logging
- MCP and editor templates that stay disabled until reviewed

## 1. Composition Model

Start with core modules, then opt into only the overlays that match the target repo.

### Core

- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/copilot-instructions.md`
- `.github/instructions/core.instructions.md`
- `.github/instructions/security.instructions.md`
- `.github/starter-modules.json`
- `.github/roles/tool-access.json`
- `.github/scripts/check-starter-workflow.ps1`
- `.github/scripts/check-starter-workflow.sh`
- `.github/scripts/check-starter-skills.ps1`
- `.github/scripts/check-starter-skills.sh`
- `.github/scripts/check-agent-contracts.ps1`
- `.github/scripts/check-agent-contracts.sh`
- `.github/hooks/agent-policy.json`
- `.github/hooks/policy-rules.tsv`

### Optional stack overlays

- `.github/instructions/frontend.instructions.md`
- `.github/instructions/react.instructions.md`
- `.github/instructions/nextjs.instructions.md`
- `.github/instructions/frontend-vitest-rtl.instructions.md`
- `.github/instructions/frontend-e2e.instructions.md`
- `.github/instructions/backend.instructions.md`
- `.github/instructions/fastapi.instructions.md`
- `.github/agents/tdd-vitest.agent.md`
- `.github/skills/api-scaffold/SKILL.md`
- `.github/skills/ui-scaffold/SKILL.md`

For test-focused overlays, keep `applyTo` patterns narrow so they target test files and test directories rather than every TS/JS file.

### Optional workflow assets

- `.github/agents/*.agent.md`
- `.github/skills/pr-review/SKILL.md`
- `.github/skills/adr-authoring/SKILL.md`
- `.github/skills/bug-triage/SKILL.md`
- `.github/skills/qa-test-plan/SKILL.md`
- `.github/skills/security-check/SKILL.md`
- `.github/skills/release-notes/SKILL.md`
- `.github/skills/approval-gated-handoffs/SKILL.md`
- `.github/schema/approval-gated-handoff-envelope.schema.json`
- `.github/examples/approval-gated-handoffs/*.json`
- `.github/scripts/check-starter-workflow.ps1`
- `.github/scripts/check-starter-workflow.sh`
- `.github/scripts/check-starter-skills.ps1`
- `.github/scripts/check-starter-skills.sh`
- `.github/scripts/check-agent-contracts.ps1`
- `.github/scripts/check-agent-contracts.sh`
- `.github/scripts/check-approval-gated-orchestration.ps1`
- `.github/scripts/check-approval-gated-orchestration.sh`
- `.vscode/mcp.json`
- `.vscode/settings.json`

Use `.github/starter-modules.json` as the source of truth for what is core, what is optional, and when each module is meant to be enabled.

## 2. Repository Layout

### Core customization

- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `.github/roles/tool-access.json`
- `.github/starter-modules.json`

### Agents and skills

- `.github/AGENTS.md`
- `.github/agents/*.agent.md`
- `.github/skills/*/SKILL.md`

### Guardrails

- `.github/hooks/agent-policy.json`
- `.github/hooks/policy-rules.tsv`
- `.github/hooks/scripts/*.ps1`
- `.github/hooks/scripts/*.sh`

### Editor and MCP templates

- `.vscode/mcp.json`
- `.vscode/settings.json`

### Team docs

- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `docs/adr/0000-template.md`
- `docs/runbooks/agentic-dev.md`
- `docs/runbooks/skills.md`
- `docs/runbooks/starter-composition.md`
- `docs/runbooks/approval-gated-handoffs.md`
- `docs/runbooks/hooks.md`
- `docs/runbooks/mcp-servers.md`

## 3. Quick Start

1. Open the repo in VS Code and confirm the baseline customizations load.
2. Read `docs/runbooks/starter-composition.md` to decide which modules are core for your target repo and which are overlays.
3. Review `.github/starter-modules.json` and remove or ignore modules that do not apply to the current stack.
4. Keep MCP servers disabled in `.vscode/mcp.json` until reviewed.
5. Start work with a short plan, small diffs, and explicit risk callouts.
6. Run the repo checks before treating workflow changes as complete.

## 3.1 Existing Project Rollout Order

For repositories that already have source code and existing `.github` content, use this order:

1. Merge minimal baseline first (`.github/copilot-instructions.md`, core/security instructions, module manifest, changelog strategy).
2. Validate baseline behavior with local checks and prompt smoke tests.
3. Add important modules in small follow-up PRs:
   - Stack overlays that match real code paths
   - High-value agents and skills the team will use immediately
   - Hook guardrails after policy review
4. Keep optional orchestration overlays disabled unless there is a clear operational need.

Use `docs/runbooks/adopting-existing-github.md` for the detailed checklist, including required vs optional vs sample-only artifacts.

## 4. How To Adapt This Starter

### For any repo

1. Keep the core baseline, security rules, hook policy, and ADR template.
2. If the target already has `.github` assets, follow `docs/runbooks/adopting-existing-github.md` and merge selectively rather than replacing the folder.
3. Rewrite examples so they match the target repo's actual source-of-truth docs and commands.
4. Keep `CHANGELOG.md` for implementation changes and `DOC-CHANGELOG.md` for documentation changes so drift is traceable.
5. Add only the agents and skills the team will actually use.
6. Keep the repo checks working as you trim or extend starter modules.

### For a stack-specific repo

1. Enable the matching overlay instructions.
2. Keep specialized skills only when the repo conventions support them.
3. Prefer the `senior-software-engineer` agent first; add test-runner-specific agents only when they create real leverage.

### For a team-specific workflow

1. Extend `.github/roles/tool-access.json` rather than duplicating tool lists in multiple places.
2. Extend `.github/hooks/policy-rules.tsv` rather than hardcoding policy into scripts.
3. Record workflow decisions in ADRs when they affect multiple repos.

## 5. Recommended Operating Pattern

1. Use one main chat as orchestrator.
2. Pull in a specialist agent only when the task clearly matches that role.
3. Use guided handoffs: each agent recommends the next agent, but the orchestrator approves the transition.
4. Use skills for repeatable playbooks such as ADR writing, bug triage, QA planning, review, release notes, security checks, or scaffolding.
5. Keep implementation and policy changes separate when possible.
6. Mirror durable workflow decisions into `docs/adr/`.

## 6. Skill Catalog

The starter currently ships these reusable skills:

- Core workflow: `adr-authoring`, `bug-triage`, `qa-test-plan`, `pr-review`, `security-check`, `release-notes`
- Optional orchestration overlay: `approval-gated-handoffs`
- Stack overlays: `api-scaffold`, `ui-scaffold`

See `docs/runbooks/skills.md` for example prompts for each one.

## 7. Hooks and Guardrails

Hook lifecycle is defined in `.github/hooks/agent-policy.json`. Block rules live in `.github/hooks/policy-rules.tsv`.

### Lifecycle

- `sessionStart`: prints the banner and writes a session log entry
- `preToolUse`: blocks risky commands and unsafe secret writes
- `postToolUse`: writes an audit record

### Defaults

- No destructive wildcard deletes
- No destructive git discard commands (`git reset --hard`, `git checkout --`)
- No piped remote script execution
- No remote content executed through `Invoke-Expression`
- No overly permissive recursive chmod operations (`chmod -R 777`)
- No likely real secrets written into `.env`
- No package installs over plain HTTP or with TLS bypassed (`pip install --trusted-host`, `--index-url http://`, `npm install --registry http://`)

If a command is blocked, use the safer alternative printed by the hook.

## 8. MCP and Editor Templates

`.vscode/mcp.json` is now a template, not an assumption about your runtime. Replace placeholder commands and paths only after the repo has chosen its actual MCP servers.

Rules:

1. Keep every entry disabled by default.
2. Use environment variables for secrets.
3. Prefer read-only validation first.
4. Document required env vars and local setup in `docs/runbooks/mcp-servers.md`.

## 9. Runbooks

- `docs/runbooks/starter-composition.md`: how to select core modules and overlays
- `docs/runbooks/adopting-existing-github.md`: minimal-first merge flow for repos with existing `.github` content
- `docs/runbooks/agentic-dev.md`: daily operating model
- `docs/runbooks/skills.md`: example prompts and usage guidance for each starter skill
- `docs/runbooks/approval-gated-handoffs.md`: optional overlay for approval-gated orchestration
- `docs/runbooks/hooks.md`: hook lifecycle, rules, and extension points
- `docs/runbooks/mcp-servers.md`: MCP template guidance and rollout safety

For the orchestration overlay, the machine-readable transition contract lives in `.github/schema/approval-gated-handoff-envelope.schema.json`, and the repo-local consistency checks live in `.github/scripts/check-approval-gated-orchestration.ps1` and `.github/scripts/check-approval-gated-orchestration.sh`.

For the general skill catalog, the repo-local consistency checks live in `.github/scripts/check-starter-skills.ps1` and `.github/scripts/check-starter-skills.sh`.

For agent handoff and escalation contract coverage, the repo-local checks live in `.github/scripts/check-agent-contracts.ps1` and `.github/scripts/check-agent-contracts.sh`.

For the overall starter workflow assets, the umbrella checks live in `.github/scripts/check-starter-workflow.ps1` and `.github/scripts/check-starter-workflow.sh`.

## 10. Change Tracking

Use the root changelogs to keep implementation and documentation history separate but cross-referenced:

- `CHANGELOG.md`: source code, scripts, config, test, and other executable changes
- `DOC-CHANGELOG.md`: Markdown, text, ADR, runbook, and other documentation changes

When a code change affects docs, add entries to both files and cross-reference them. When a docs-only clarification has no implementation impact, record `Related code: None` in `DOC-CHANGELOG.md`.

## 11. Validation Helpers

Use the repo-local checks to keep the starter consistent as it evolves:

- `.github/scripts/check-starter-workflow.ps1` or `.github/scripts/check-starter-workflow.sh`: umbrella check for starter workflow assets
- `.github/scripts/check-starter-skills.ps1` or `.github/scripts/check-starter-skills.sh`: verify manifest-listed skill directories and `SKILL.md` files
- `.github/scripts/check-agent-contracts.ps1` or `.github/scripts/check-agent-contracts.sh`: verify required handoff memory and escalation/failure sections in agent files and related runbook references
- `.github/scripts/check-approval-gated-orchestration.ps1` or `.github/scripts/check-approval-gated-orchestration.sh`: verify the optional orchestration overlay assets, docs, and schema references

## 12. ADR Workflow

Use `docs/adr/0000-template.md` for decisions that affect architecture, workflow, security posture, or cross-repo conventions.

## 13. First Improvements To Make In A New Repo

1. Replace example doc references with the repo's actual source-of-truth docs.
2. Trim unused overlay modules from `.github/starter-modules.json`.
3. Start using `CHANGELOG.md` and `DOC-CHANGELOG.md` from the first real repo adaptation so drift stays visible.
4. Add one project-specific skill or agent only after a repeated workflow need is proven.
5. Run the validation helpers after any starter-level change so the manifest, docs, skills, and overlays stay aligned.
