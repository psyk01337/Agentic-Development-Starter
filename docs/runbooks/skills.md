# Skills Runbook

This runbook gives teams quick example prompts for each starter skill so adoption is faster and more consistent.

## Core Workflow Skills

### `adr-authoring`

Use when a design or workflow decision should be recorded as an ADR.

Example prompts:

- `Use adr-authoring to draft an ADR for enabling the approval-gated orchestration overlay in this repo.`
- `Turn this architecture decision into an ADR using the repo template and keep it concise.`

### `bug-triage`

Use when symptoms are still ambiguous and the safest next step is to narrow the problem before implementation.

Example prompts:

- `Use bug-triage for this regression: users intermittently lose form state after navigation.`
- `Run bug-triage on this issue and separate confirmed evidence from likely causes.`

### `qa-test-plan`

Use when a feature or change needs an explicit minimum validation plan before signoff.

Example prompts:

- `Use qa-test-plan for the new account settings workflow and focus on risky user flows.`
- `Create a minimal QA test plan for this auth change, including failure cases and coverage gaps.`

### `pr-review`

Use when you want a findings-first review of correctness, regressions, and maintainability.

Example prompts:

- `Use pr-review on my current diff. Focus on correctness, tests, regressions, and docs impact.`
- `Review this change with pr-review and call out the smallest safe fixes first.`

### `security-check`

Use when a change touches auth, input handling, file or network access, secrets, or dependencies.

Example prompts:

- `Run security-check on this endpoint change and focus on authz, logging, and injection risk.`
- `Use security-check for these config changes and tell me whether any secret-handling or path risks were introduced.`

### `release-notes`

Use when you need concise user-facing and internal release summaries.

Example prompts:

- `Use release-notes for the merged changes in this sprint and separate user-facing notes from internal notes.`
- `Draft release notes for this week’s changes, including upgrade notes and verification.`

### `session-compaction`

Use before context compaction, handoff, or long-running session reset.

Example prompts:

- `Use session-compaction before I compact this chat. Preserve decisions, files changed, validation, and next action.`
- `Summarize this task for the next agent using the session-compaction skill.`

### `memory-curation`

Use when deciding whether a candidate memory belongs in session memory, repo truth, optional durable memory, or nowhere.

Example prompts:

- `Use memory-curation for this lesson learned and tell me where it should live.`
- `Check whether this preference is safe for durable memory or should become a runbook update.`

### `repo-onboarding`

Use when an agent needs fast orientation to a repo's workflow assets, source-of-truth docs, and validation commands.

Example prompts:

- `Use repo-onboarding to orient to this repository before making changes.`
- `Map this repo's source-of-truth docs, agents, skills, hooks, prompts, and validation commands.`

### `ci-failure-debugging`

Use when CI fails and the next safe action is unclear.

Example prompts:

- `Use ci-failure-debugging on this workflow failure and identify the smallest local fix.`
- `Triage this failing starter validation job without disabling checks.`

### `migration-planning`

Use when adopting, trimming, or upgrading starter modules in an existing repository.

Example prompts:

- `Use migration-planning to move this repo to team mode without replacing existing .github assets.`
- `Plan an advanced-mode rollout with prompts, hooks, evals, and memory policy kept disabled until reviewed.`

### `tool-surface-audit`

Use when enabling or comparing an agent platform, MCP server, runtime, hook mechanism, or memory provider.

Example prompts:

- `Use tool-surface-audit to compare this agent runtime against the starter tool matrix.`
- `Audit whether enabling browser automation MCP is safe for this repo.`

### `problem-structuring`

Use when a technical problem is too complex or ambiguous for straightforward discovery and needs structured decomposition before the analyst or tech-planner chain begins. Applies MECE issue trees, hypothesis-driven analysis, impact × feasibility prioritization, Pyramid Principle synthesis, and SCQA communication.

Example prompts:

- `Use problem-structuring to decompose this performance degradation across three services before we investigate.`
- `Structure this feature request into a MECE issue tree with hypotheses and an analysis plan.`
- `Apply the Pyramid Principle to synthesize these findings into a headline recommendation with supporting arguments.`

## Optional Overlay Skills

### `approval-gated-handoffs`

Use only when the repo has explicitly enabled the orchestration overlay and you need an approval-gated transition between specialists.

Example prompts:

- `Use approval-gated-handoffs to draft the next transition from tech-planner to senior-software-engineer.`
- `Coordinate the next specialist handoff with explicit approval and fallback to manual if approval is missing.`

### `verification-evidence-loop`

Use only when the repo has enabled the supervisor orchestration overlay and a change needs direct verification evidence before the orchestrator declares completion. The skill reads the per-surface evidence kinds from `evidenceRequirements` in `.github/roles/orchestration-policy.json`, produces `VERIFIED` / `NOT_VERIFIED` / `INCONCLUSIVE` results, and emits `delegation-result.schema.json`-shaped verification entries. `INCONCLUSIVE` is never a success.

Example prompts:

- `Use verification-evidence-loop to verify this API change and produce the verification record.`
- `Run verification-evidence-loop for this bugfix and keep INCONCLUSIVE out of the success path.`

### `adversarial-review`

Use only when the repo has enabled the supervisor orchestration overlay and a completed change must be interrogated before it is relied on. Attempts to prove the implementation wrong across thirteen lenses and returns deduplicated, evidence-first findings; evidence outranks voting.

Example prompts:

- `Use adversarial-review to interrogate this diff and attempt to prove it wrong.`
- `Run adversarial-review on this fix, cover the security and failure-handling lenses, and report the six-field findings.`

### `arena-bakeoff`

Use only when the repo has enabled the supervisor orchestration overlay and alternative implementations provide meaningful value, such as architecture decisions, API design, difficult algorithms, complex refactors, or ambiguous abstractions. Runs N isolated candidates, scores them against one rubric, and synthesizes only compatible improvements; never averages incompatible architectures.

Example prompts:

- `Use arena-bakeoff to compare three candidate designs for this API and select a base.`
- `Run arena-bakeoff on this refactor: isolated worktrees per candidate, one rubric, and only compatible improvements synthesized.`

### `swarm`

Use only when the repo has enabled the supervisor orchestration overlay and one task decomposes into different independent slices that can run concurrently. Unlike `arena-bakeoff`, which competes on the same problem, a swarm runs each slice on a different problem; it detects shared mutable state before parallel execution and aggregates results only after all required slices finish.

Example prompts:

- `Use swarm to split this change into backend, tests, and documentation slices and run them concurrently.`
- `Run swarm on this migration: audit, backend, and docs slices, with write sets checked before parallel execution.`

### `prose-cleanup`

Applies repo-wide to agent-produced prose — agent responses, ADRs, PR descriptions, documentation, handoffs, and code comments — even though it ships under the supervisor orchestration overlay's manifest section. Removes canned AI introductions, redundant summaries, unnecessary headings, fake certainty, verbose restatement, repetitive conclusions, and excessive conversational filler while preserving technical detail. It is a writing-quality filter, not a context compressor, and is not responsible for workflow-state storage.

Example prompts:

- `Use prose-cleanup on this PR description to cut the filler and keep every technical detail.`
- `Run prose-cleanup over this ADR and handoff before review.`

### `session-compactor`

Use when a long working history must be compressed into a compact continuation brief before compaction, reset, or resumption. Unlike core `session-compaction`, which preserves handoff-time state (current plan, acceptance criteria, validation evidence, next recommended action), `session-compactor` compacts accumulated engineering context into the ten-field brief — current objective, locked decisions, important constraints, relevant architecture, files changed, known failures, verified facts, unresolved questions, current phase, and next actions — and discards conversational filler. The brief is not workflow-state storage and is not a completion declaration. Like `prose-cleanup`, it is repo-wide but ships under the supervisor orchestration overlay's manifest section for pattern continuity.

Example prompts:

- `Use session-compactor to compress this session before compaction into a compact continuation brief.`
- `Turn this long working history into the ten-field brief with session-compactor and keep unresolved risks intact.`

### `decision-trail`

Use when a complex or autonomous task must leave an auditable decision trail: per-decision entries with suggested fields (timestamp, phase, decision, reason, evidence, result) and evidence as pointers — test output, commit, file and line, screenshot, trace, browser artifact, benchmark, command output — rather than pasted content. Trivial changes create no trail artifacts, and the trail is never workflow state and never a completion declaration. Like `prose-cleanup` and `session-compactor`, it is repo-wide but ships under the supervisor orchestration overlay's manifest section for pattern continuity.

Changelogs record landed changes, ADRs record durable decisions with tradeoffs, and `session-compactor` produces continuation briefs. The decision trail records task-time decisions and points to those repo records instead of duplicating them; it can supply context to compaction without replacing it.

Example prompts:

- `Use decision-trail to record the decisions from this task with pointers to the validation output.`
- `Keep a decision trail for this multi-phase change and point each entry at its evidence.`

### `api-scaffold`

Use when a repo has a stable backend pattern and you want a scaffold from a contract or endpoint spec.

Example prompts:

- `Use api-scaffold for POST /orders/{id}/cancel with auth required, reason:string, and 200/400/403/404 responses.`
- `Scaffold a queue consumer from this event contract using api-scaffold and include tests and docs stubs.`

### `ui-scaffold`

Use when a repo has an established UI framework and you want a structured screen or interaction scaffold.

Example prompts:

- `Use ui-scaffold for an account settings screen with profile edit, password update, and loading/error/empty/success states.`
- `Use ui-scaffold to draft the component structure and state model for this onboarding workflow.`
- `Use ui-scaffold to draft a Livewire component and Blade view stubs for this settings form, honoring the repo's Livewire overlay.`
- `Use ui-scaffold to outline a Filament resource and form schema for this admin screen.`

### `game-perf-triage`

Use when a game stutters, drops frames, hitches on load, or grows in memory and the cause is unknown. Forces a measured budget, a classified bottleneck, one verified fix, and a matched after-measurement.

Example prompts:

- `Use game-perf-triage on this frame drop in the combat scene.`
- `The game stutters when many enemies spawn; find the bottleneck before I optimize.`
- `Triage the memory growth across scene transitions.`
- `We load everything at boot and first load is slow; triage it.`

## Consistency Check

Use the starter skill checks to confirm the manifest and skill directories stay aligned:

- PowerShell: `.github/scripts/check-starter-skills.ps1`
- Shell: `.github/scripts/check-starter-skills.sh`

These checks verify that every skill path listed in `.github/starter-modules.json` exists and includes a `SKILL.md` file.

They also verify every skill directory has a lowercase hyphenated name and `SKILL.md` frontmatter with `name` and `description`.

If you want one entry point for the broader starter checks, use:

- PowerShell: `.github/scripts/check-starter-workflow.ps1`
- Shell: `.github/scripts/check-starter-workflow.sh`
