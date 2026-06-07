You are a senior AI agent systems architect, GitHub Copilot customization expert, agentic development workflow designer, DevSecOps engineer, and technical documentation maintainer.

Repository to improve:
https://github.com/psyk01337/Agentic-Development-Starter

Current date context:
June 6, 2026.

Mission:
Upgrade this repository from a strong VS Code/Copilot-oriented agentic development starter into a production-grade, cross-agent, repo-native AI development workflow starter for modern 2026 AI-assisted software development.

The repo should remain lightweight, modular, safe by default, and composable. Do not turn it into a full agent runtime. Instead, make it a high-quality workflow/governance starter that can be used with GitHub Copilot, VS Code agent mode, Copilot cloud agent, Claude Code, Codex, Cursor, OpenCode, and Hermes-style runtimes.

Core positioning:
“Agentic Development Starter is a repo-native workflow, safety, and governance starter for AI-assisted software development. It standardizes instructions, prompts, agents, skills, hooks, MCP templates, memory policy, handoffs, validation, and evaluation so teams can ship changes with consistent guardrails and auditability.”

Important distinction:
This repository is not trying to become Hermes Agent. Hermes is a stateful runtime. This repository should be the repo-level operating system for safe AI-assisted development. Hermes and Honcho should be supported through optional overlays, not required by default.

Primary goals:
1. Fix repository correctness and script formatting issues.
2. Add missing prompt-file workflows under `.github/prompts`.
3. Add CI validation so the starter verifies itself.
4. Add an evaluation/golden-task harness for testing agent behavior.
5. Add optional Hermes runtime and Honcho memory overlays.
6. Add a clear memory strategy that separates repo truth, session context, and durable memory.
7. Add a tool-surface compatibility matrix for different AI coding agents.
8. Improve governance, documentation, safety, and adoption experience.
9. Keep all MCP and high-risk automation disabled by default until reviewed.
10. Preserve the repo’s composable module model.

Non-negotiable rules:
- Do not remove existing useful structure unless replacing it with something clearly better.
- Do not enable dangerous tools, shell auto-execution, MCP servers, or memory backends by default.
- Do not store secrets, credentials, tokens, raw production logs, or sensitive customer data.
- Keep instructions concise, deterministic, and usable by coding agents.
- Prefer small, auditable changes.
- Every new workflow must have a validation path.
- Every new file must have a clear purpose.
- Update `CHANGELOG.md` and `DOC-CHANGELOG.md` when documentation or starter behavior changes.
- Keep this starter framework/language agnostic unless an overlay is intentionally stack-specific.

Phase 1 — Repository health and formatting hardening:
Inspect all existing files, especially:
- `.github/scripts/*.sh`
- `.github/scripts/*.ps1`
- `.github/hooks/scripts/*.sh`
- `.github/hooks/scripts/*.ps1`
- `.github/hooks/policy-rules.tsv`
- `.github/skills/*/SKILL.md`
- `.github/agents/*.agent.md`
- `.github/instructions/*.instructions.md`
- `.github/starter-modules.json`

Fix any file that appears minified, single-line, malformed, or hard to review.

Critical fixes:
- Ensure all shell scripts have proper line breaks after the shebang.
- Ensure all shell scripts use strict mode where appropriate:
  `set -euo pipefail`
- Ensure `.tsv` files are actual tab-separated files if the parser expects tabs.
- Ensure JSON files are valid and formatted.
- Ensure Markdown files are readable and lint-friendly.
- Ensure scripts have helpful error messages.
- Ensure validation scripts fail fast and return non-zero exit codes on failure.

Add or improve validation for:
- Required core files exist.
- Required optional module files are referenced correctly.
- Every skill directory has a valid `SKILL.md`.
- Every skill has YAML frontmatter with at minimum:
  - `name`
  - `description`
- Skill names are lowercase and hyphenated.
- Every custom agent has a clear role, scope, allowed tools, and handoff behavior.
- Hook policy rules parse correctly.
- Dangerous commands are denied by policy.
- MCP templates remain disabled by default.
- Approval-gated handoff examples validate against schema.

Phase 2 — Add CI workflows:
Create `.github/workflows/` if missing.

Add:
1. `.github/workflows/starter-validation.yml`
   - Runs on pull request and push.
   - Executes all starter validation scripts.
   - Runs on Ubuntu.
   - If practical, also run PowerShell scripts using `pwsh`.

2. `.github/workflows/markdown-quality.yml`
   - Checks Markdown formatting.
   - Checks for broken obvious local links where practical.
   - Does not require heavy external dependencies unless justified.

3. `.github/workflows/hook-policy-tests.yml`
   - Tests policy rules using safe fixture inputs.
   - Must verify blocking for examples like:
     - `rm -rf /`
     - `curl ... | bash`
     - `wget ... | sh`
     - `git reset --hard`
     - writing secrets to `.env`
     - HTTP package registries
   - Must verify safe commands are not falsely blocked.

4. `.github/workflows/skill-contract-tests.yml`
   - Validates skill metadata.
   - Validates required `SKILL.md` naming.
   - Validates optional scripts/resources referenced by skills exist.

Phase 3 — Add reusable prompt files:
Create `.github/prompts/`.

Add these prompt files:
- `.github/prompts/onboard-existing-repo.prompt.md`
- `.github/prompts/plan-small-feature.prompt.md`
- `.github/prompts/implement-small-diff.prompt.md`
- `.github/prompts/review-current-diff.prompt.md`
- `.github/prompts/create-adr.prompt.md`
- `.github/prompts/generate-test-plan.prompt.md`
- `.github/prompts/prepare-release-notes.prompt.md`
- `.github/prompts/migrate-to-starter.prompt.md`
- `.github/prompts/security-review.prompt.md`
- `.github/prompts/debug-failing-ci.prompt.md`

Prompt-file rules:
- Each prompt should be task-specific.
- Each prompt should tell the agent what context to inspect first.
- Each prompt should include explicit deliverables.
- Each prompt should include safety boundaries.
- Each prompt should include “stop and ask before destructive changes.”
- Each prompt should include expected output format.
- Prompt files should be reusable slash-command style tasks, not broad always-on instructions.

Phase 4 — Improve custom agents:
Review `.github/agents/*.agent.md`.

Make sure each agent has:
- Clear purpose.
- When to use.
- When not to use.
- Allowed tool assumptions.
- Required source files to inspect.
- Output format.
- Handoff rules.
- Safety boundaries.
- Verification expectations.

Recommended agents to keep or add:
- `orchestration-coordinator.agent.md`
- `product-analyst.agent.md`
- `solution-architect.agent.md`
- `senior-engineer.agent.md`
- `code-reviewer.agent.md`
- `security-reviewer.agent.md`
- `qa-test-planner.agent.md`
- `process-improvement.agent.md`
- `documentation-maintainer.agent.md`
- `tdd-vitest.agent.md`

Do not create agents that overlap too much. If two agents do the same job, consolidate.

Phase 5 — Improve skills:
Review existing skills and add missing ones.

Existing useful skills likely include:
- ADR authoring
- Bug triage
- PR review
- QA test plan
- Security check
- Release notes
- API scaffold
- UI scaffold
- Approval-gated handoffs

Add these skills if missing:
- `.github/skills/session-compaction/SKILL.md`
- `.github/skills/memory-curation/SKILL.md`
- `.github/skills/repo-onboarding/SKILL.md`
- `.github/skills/ci-failure-debugging/SKILL.md`
- `.github/skills/migration-planning/SKILL.md`
- `.github/skills/tool-surface-audit/SKILL.md`

Skill rules:
- Use skills for multi-step workflows.
- Use prompt files for repeatable one-off tasks.
- Use custom instructions for always-on standards.
- Use agents for specialized roles/personas.
- Use hooks for deterministic enforcement.
- Use MCP only when external tools/data are truly needed.

Every skill must include:
- YAML frontmatter.
- A concise description that helps an agent know when to use it.
- Inputs expected.
- Procedure.
- Output format.
- Verification checklist.
- Safety notes.
- Any referenced scripts/resources.

Phase 6 — Add memory strategy:
Create:
- `.github/instructions/memory.instructions.md`
- `docs/runbooks/memory-strategy.md`
- `.github/examples/memory/honcho-policy.example.md`
- `.github/examples/memory/hermes-memory-provider.example.md`

Memory strategy:
Separate memory into three layers.

Layer 1 — Session/handoff memory:
Use for:
- Current task plan.
- Current acceptance criteria.
- Open blockers.
- Files changed.
- Tests run.
- Next recommended step.

Do not use for:
- Permanent project decisions.
- User secrets.
- Customer confidential information.

Layer 2 — Repo truth:
Use repo files for durable facts:
- Architecture decisions.
- Coding standards.
- API contracts.
- Security policies.
- Testing strategy.
- Runbooks.
- Changelogs.
- Dependency decisions.
- Migration decisions.

Repo truth should live in:
- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `.github/AGENTS.md`
- `.github/skills/*/SKILL.md`
- `docs/adr/*.md`
- `docs/runbooks/*.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`

Layer 3 — Optional durable agent memory:
Use optional memory providers such as Honcho only for:
- Stable user/team preferences.
- Long-running project context.
- Repeated workflow patterns.
- Lessons learned across sessions.
- Non-sensitive collaboration preferences.

Never store:
- Secrets.
- API keys.
- Passwords.
- Customer private data.
- Sensitive logs.
- Production credentials.
- Legal/medical/financial private information.
- Anything regulated unless explicitly approved and documented.

Honcho should be optional, disabled by default, and documented as an integration overlay.

Recommended Honcho policy:
- Default to project/repo scoped memory, not global memory.
- Prefer `sessionStrategy: per-repo` or `per-directory`.
- Set a context token cap.
- Keep dialectic depth conservative by default.
- Keep save behavior explicit.
- Provide pruning/review instructions.
- Include a memory audit checklist.

Phase 7 — Add Hermes and Honcho optional overlays:
Create:
- `.github/instructions/hermes-runtime.instructions.md`
- `.github/instructions/honcho-memory.instructions.md`
- `docs/runbooks/hermes-runtime.md`
- `docs/runbooks/honcho-memory.md`
- `.github/examples/hermes/hermes-profile.example.md`
- `.github/examples/honcho/honcho.config.example.json`

Hermes overlay should explain:
- This repo is not a Hermes replacement.
- Hermes is a runtime.
- This repo supplies repo rules, skills, prompts, policies, and handoff contracts.
- Hermes should read repo truth before acting.
- Hermes should honor hook/security policies.
- Hermes should use optional memory only within the memory policy.
- Hermes should not self-modify core repo instructions without explicit approval.

Honcho overlay should explain:
- Honcho is optional.
- Honcho is for durable memory/user/project modeling.
- Honcho must not become the source of truth.
- Repo files remain authoritative.
- Honcho memory should be scoped, reviewed, and pruned.
- Sensitive data must not be stored.

Phase 8 — Add tool-surface compatibility matrix:
Create:
- `docs/runbooks/tool-surface-matrix.md`

Include a matrix for:
- GitHub Copilot VS Code agent mode
- GitHub Copilot cloud agent
- GitHub Copilot CLI
- Claude Code
- Codex
- Cursor
- OpenCode
- Hermes Agent

Map abstract operations:
- Read files
- Search files
- Edit/apply patch
- Run terminal
- Run tests
- Browser automation
- GitHub issues/PRs
- MCP tools
- Hooks/policies
- Skills
- Prompt files
- Custom agents
- Memory
- Handoffs

For each platform, describe:
- Supported directly.
- Supported through MCP.
- Supported through repo convention.
- Unsupported/unknown.
- Safety caveats.

Phase 9 — Add eval/golden-task harness:
Create:
- `evals/README.md`
- `evals/tasks/simple-bugfix.md`
- `evals/tasks/add-api-endpoint.md`
- `evals/tasks/frontend-component.md`
- `evals/tasks/security-review.md`
- `evals/tasks/update-docs-and-changelog.md`
- `evals/tasks/debug-failing-ci.md`
- `evals/expected/simple-bugfix.checklist.md`
- `evals/expected/add-api-endpoint.checklist.md`
- `evals/expected/frontend-component.checklist.md`
- `evals/expected/security-review.checklist.md`
- `evals/run-evals.sh`
- `evals/run-evals.ps1`

Eval goals:
- Test whether agents follow repo instructions.
- Test whether agents read the right source-of-truth files.
- Test whether agents keep changes small.
- Test whether agents update tests.
- Test whether agents update documentation/changelogs.
- Test whether agents avoid unsafe commands.
- Test whether agents produce useful handoffs.
- Test whether agents follow memory policy.

The eval harness does not need to run real LLMs at first. It can start as a checklist-driven manual/semi-automated harness. Make it easy to expand later.

Phase 10 — Improve MCP posture:
Review:
- `.vscode/mcp.json`
- `docs/runbooks/mcp-servers.md`

Ensure:
- All MCP servers are disabled by default.
- Example MCP configs are clearly templates.
- No real tokens or secrets exist.
- Each MCP server has a purpose, required permissions, and risks.
- Browser automation MCP, GitHub MCP, database MCP, and file-system MCP have explicit safety notes.
- Add “MCP approval checklist” before enabling any server.

Phase 11 — Improve hook policy:
Review:
- `.github/hooks/agent-policy.json`
- `.github/hooks/policy-rules.tsv`
- `.github/hooks/scripts/*`

Add test fixtures for:
- Allowed safe commands.
- Denied destructive commands.
- Denied secret exposure.
- Denied package registry downgrade.
- Denied unreviewed network shell execution.
- Denied force push.
- Denied broad deletion.
- Denied editing of core policy files without approval.

Add docs explaining:
- What hooks can enforce.
- What hooks cannot enforce.
- How to safely add a policy rule.
- How to debug false positives.
- How to handle emergency bypass with documented approval.

Phase 12 — Improve starter adoption:
Create or improve:
- `docs/runbooks/starter-adoption.md`
- `docs/runbooks/starter-composition.md`
- `docs/runbooks/agentic-dev.md`

Add adoption paths:
1. Minimal mode:
   - Core instructions only.
   - Security overlay.
   - Basic validation.

2. Team mode:
   - Agents.
   - Skills.
   - Prompt files.
   - Hooks.
   - CI validation.

3. Advanced mode:
   - Approval-gated handoffs.
   - MCP templates.
   - Evals.
   - Memory policy.
   - Hermes/Honcho optional overlays.

4. Enterprise mode:
   - Org-level instructions.
   - Private shared skills.
   - Centralized policy.
   - Audit requirements.
   - Security review.

Phase 13 — README upgrade:
Rewrite or improve `README.md` so it clearly explains:
- What the starter is.
- What it is not.
- Why it exists.
- How it compares to Hermes-style runtimes.
- Quick start.
- Folder structure.
- Core vs optional modules.
- How to add prompts.
- How to add skills.
- How to use agents.
- How hooks work.
- How MCP is handled safely.
- How memory is handled.
- How to run validation.
- How to adopt in an existing repo.
- Recommended workflow examples.

README should include:
- “Use this when…”
- “Do not use this when…”
- “Minimal install”
- “Full install”
- “Security defaults”
- “Hermes/Honcho integration”
- “Validation commands”
- “Roadmap”

Phase 14 — Documentation quality:
Update:
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- Relevant runbooks
- Any schema docs if changed

Every doc should be:
- Direct.
- Actionable.
- Agent-readable.
- Human-readable.
- Free of vague filler.
- Written as operational guidance.

Phase 15 — Final verification:
Before finishing:
1. Run all validation scripts.
2. Run CI-equivalent local commands where possible.
3. Validate JSON.
4. Validate shell scripts parse.
5. Validate PowerShell scripts parse.
6. Validate skill frontmatter.
7. Validate hook policy fixtures.
8. Validate docs link to created files.
9. Confirm no secrets were added.
10. Confirm MCP remains disabled by default.
11. Confirm Honcho/Hermes overlays are optional.
12. Confirm changelogs were updated.
13. Produce a final summary with:
   - Files changed.
   - Files added.
   - Validation run.
   - Known limitations.
   - Recommended next steps.

Expected final deliverables:
- A cleaner, validated repo structure.
- `.github/prompts/` with reusable prompt files.
- Improved `.github/agents/`.
- Improved `.github/skills/`.
- CI workflows.
- Evals harness.
- Memory strategy docs.
- Hermes runtime overlay.
- Honcho memory overlay.
- Tool-surface compatibility matrix.
- Improved MCP and hook documentation.
- Updated README.
- Updated changelogs.

Final output format:
Provide:
1. Executive summary.
2. Key design decisions.
3. Files added/changed.
4. Validation results.
5. Remaining risks.
6. Next recommended improvements.

Work carefully, preserve existing intent, and prioritize correctness, safety, composability, and real-world usefulness over flashy complexity.