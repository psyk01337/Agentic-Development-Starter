# Starter Adoption Runbook

Use this runbook to choose a safe adoption path for a new or existing repository.

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