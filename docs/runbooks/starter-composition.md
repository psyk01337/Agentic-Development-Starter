# Starter Composition Runbook

This runbook explains how to adapt the starter to a target repository without dragging along stack-specific assumptions that do not apply.

## 1. Start With Core Modules

Keep these modules in almost every repo:

- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/copilot-instructions.md`
- `.github/instructions/core.instructions.md`
- `.github/instructions/security.instructions.md`
- `.github/starter-modules.json`
- `.github/roles/tool-access.json`
- `.github/hooks/agent-policy.json`
- `.github/hooks/policy-rules.tsv`
- `docs/adr/0000-template.md`

These files define the baseline delivery rules, safety posture, hook contract, module registry, and the default traceability logs for implementation and documentation changes.

Keep the logs split on purpose:

- `CHANGELOG.md` for source code, scripts, executable config, tests, and behavior-affecting changes
- `DOC-CHANGELOG.md` for Markdown, text, ADRs, runbooks, and other documentation updates

Cross-reference related entries when code and docs evolve together so discrepancies stay visible.

## 2. Add Overlays Only When The Repo Needs Them

### JavaScript or TypeScript UI repos

Add or keep:

- `.github/instructions/frontend.instructions.md`
- `.github/skills/ui-scaffold/SKILL.md`
- `.github/agents/tdd-vitest.agent.md` when Vitest is the real test runner

### Python or SQL backend repos

Add or keep:

- `.github/instructions/backend.instructions.md`
- `.github/skills/api-scaffold/SKILL.md`

### Other stacks

Use the core modules first, then add new overlays only after the repo has stable conventions worth encoding.

## 3. Prefer Generic Roles Before Specialized Agents

The default specialist set is:

- `analyst`
- `tech-planner`
- `architecture-reviewer`
- `senior-software-engineer`
- `code-reviewer`
- `qa`
- `process-improvement`

Use `tdd-vitest` only when strict Vitest TDD is actually part of the repo workflow.

Shared tool boundaries are documented in `.github/roles/tool-access.json`. Update that file before duplicating tool intent across multiple agents.

The core starter uses guided handoffs, not automatic handoffs. If a target repo later needs agent-to-agent orchestration, add it as an optional overlay with explicit approval and audit behavior.

The optional approval-gated orchestration overlay is documented in `docs/runbooks/approval-gated-handoffs.md` and should remain default-disabled unless a team has an explicit reason to adopt it.

## 4. Keep Hook Policy Data-Driven

Hook lifecycle configuration lives in `.github/hooks/agent-policy.json`. Block rules live in `.github/hooks/policy-rules.tsv`.

To extend policy safely:

1. Add or adjust a rule in `.github/hooks/policy-rules.tsv`.
2. Keep the reason and safer alternative concrete.
3. Test both PowerShell and shell behavior if your team uses both.

Avoid hardcoding new policy directly into the scripts unless the hook mechanism itself is changing.

## 5. Keep MCP Templates As Templates

`.vscode/mcp.json` should describe safe shapes and placeholders, not assume a language runtime or local tool path that every repo will have.

Rules:

1. Disable all entries by default.
2. Use placeholders until the repo has chosen real servers.
3. Keep secrets out of committed config.
4. Document env vars and local setup in the runbook.

## 6. Replace Starter Examples Early

Before treating the starter as complete for a new repo:

1. Replace example doc references with the repo's real source-of-truth docs.
2. Start recording implementation updates in `CHANGELOG.md` and documentation updates in `DOC-CHANGELOG.md`.
3. Trim modules that do not apply.
4. Rename or remove skills that imply patterns the repo does not use.
5. Capture workflow decisions in ADRs when they affect multiple teams or repos.
