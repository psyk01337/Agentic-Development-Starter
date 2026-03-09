# Agentic Development Runbook

This runbook describes the daily operating model once the starter has been composed for a target repo. For starter selection and module trimming, begin with `docs/runbooks/starter-composition.md`.

## 1) Start with Multi-Agent Sessions

1. Keep one main chat as orchestrator.
2. Spawn subagents for parallel tasks: research, implementation, review.
3. Merge results in the main session and decide next action.
4. Prefer the generic `senior-software-engineer` agent unless the repo has a justified stack-specific implementation overlay such as `tdd-vitest`.
5. Use guided handoffs: each specialist should recommend the next agent, explain why, and call out blockers or approvals still needed.

## 1a) Common Guided Chains

### Simple fix

1. Start with `senior-software-engineer`.
2. Hand off to `code-reviewer`.

### Clear feature with user impact

1. Start with `senior-software-engineer`.
2. Hand off to `code-reviewer`.
3. Hand off to `qa`.

### Unclear problem or risky change

1. Start with `analyst`.
2. Hand off to `tech-planner` when design or tradeoff work is needed.
3. Hand off to `architecture-reviewer` when the change touches contracts, boundaries, or platform shape.
4. Hand off to `senior-software-engineer` for implementation.
5. Hand off to `code-reviewer` and `qa` before calling the work done.

### Workflow asset change

1. Start with `process-improvement`.

### Approval-gated overlay flow

1. Start with `orchestration-coordinator` only if the repo has enabled the orchestration overlay.
2. Require an explicit approval checkpoint before the coordinator drafts or advances the next handoff.
3. Fall back to normal guided handoffs whenever approval is missing, rejected, or stale.

## 2) Use Agent Plugins as Team Bundles

1. Open Extensions view.
2. Install or enable your team starter bundle (skills/tools/hooks).
3. Verify loaded customizations in Agent Debug panel.

## 3) Use Browser Tools in a Closed Loop

1. Implement the UI/code change.
2. Run browser verification for key flows.
3. Capture screenshot and console errors.
4. Fix issues.
5. Re-verify and record pass/fail notes.

## 4) Keep Session Memory Useful

1. Store current plan and constraints in session memory.
2. Maintain a short decision log during the session.
3. Mirror major decisions into ADRs under `docs/adr/`.
4. When a task changes executable behavior, add or update an entry in `CHANGELOG.md`.
5. When a task changes Markdown, text, ADRs, or runbooks, add or update an entry in `DOC-CHANGELOG.md`.

## 5) Compact Context After Milestones

1. Use `/compact` after each meaningful milestone.
2. Preserve decisions, interfaces, and open risks.
3. Drop solved details that no longer affect decisions.

## 6) Fork Sessions for Alternatives

1. Use `/fork` to explore alternative implementations.
2. Compare fork outputs quickly (risk, effort, correctness).
3. Bring only the winning approach back to the main thread.

## 7) Debug Agent Behavior

1. Open Agent Debug panel.
2. Inspect event timeline, tool calls, and loaded customizations.
3. Confirm instructions, skills, hooks, and MCP servers were applied.
4. Fix mis-scoped `applyTo` patterns or hook policy mismatches.

## 8) Create Customizations from Chat

Use chat commands to generate repo assets quickly:

- `/create-prompt`
- `/create-instruction`
- `/create-skill`
- `/create-agent`
- `/create-hook`

Then move finalized outputs into `.github/*` for team sharing.

## 8a) Use Skills For Repeatable Work

Reach for skills when the work is bounded and format-sensitive:

- `adr-authoring` for decision records
- `bug-triage` for narrowing symptoms and next steps
- `qa-test-plan` for risky flow coverage and minimal validation planning
- `pr-review` for findings-first review
- `security-check` for focused security review
- `release-notes` for release summaries
- stack-specific scaffold skills when the repo actually uses those patterns

See `docs/runbooks/skills.md` for example prompts for each skill and quick guidance on when to reach for them.

## 9) Keep Modules Intentional

1. Review `.github/starter-modules.json` before enabling new workflow assets.
2. Keep core modules stable and treat stack-specific assets as overlays.
3. Add new agents or skills only after a repeated workflow need is proven.
4. Keep full automatic handoffs out of core unless the repo later adds a dedicated orchestration overlay.

If you do enable that overlay, keep the richer approval metadata and transition records inside the overlay contract rather than expanding the core handoff contract for every repo.

## 9a) Keep Changelogs Cross-Referenced

1. Use `CHANGELOG.md` for code, scripts, tests, runtime config, and other executable changes.
2. Use `DOC-CHANGELOG.md` for Markdown, text, ADR, runbook, and onboarding changes.
3. Cross-reference related entries when code and docs change together.
4. Record known discrepancies explicitly instead of leaving drift implicit.

## 10) Optional: Kitty Graphics Protocol

Use terminal image rendering only when visual diffs or screenshot-heavy debugging makes it faster.

## 11) Accessibility (Keyboard-First)

- Prefer command palette and keyboard shortcuts for core actions.
- Ensure browser verification includes keyboard navigation checks.
- Keep runbooks and prompts concise for faster screen-reader navigation.
