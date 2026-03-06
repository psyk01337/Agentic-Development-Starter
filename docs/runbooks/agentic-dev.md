# Agentic Development Runbook (Feb 2026)

## 1) Start with Multi-Agent Sessions

1. Keep one main chat as orchestrator.
2. Spawn subagents for parallel tasks: research, implementation, review.
3. Merge results in the main session and decide next action.

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

## 9) Optional: Kitty Graphics Protocol

Use terminal image rendering only when visual diffs or screenshot-heavy debugging makes it faster.

## 10) Accessibility (Keyboard-First)

- Prefer command palette and keyboard shortcuts for core actions.
- Ensure browser verification includes keyboard navigation checks.
- Keep runbooks and prompts concise for faster screen-reader navigation.
