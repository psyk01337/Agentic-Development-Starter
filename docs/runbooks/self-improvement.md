# Repo Self-Improvement Loop

Use this runbook to run bounded, on-demand improvements to this repository without turning the repository into a full-time framework project.

## Purpose

The loop lets an agent audit the repo, select one high-value improvement, implement it, validate it, and record the result. It is intentionally narrow: one PR-sized change per run, with explicit stop conditions and approval boundaries.

This is not an unattended scheduler. The agent runs the loop when a human invokes [improve-repo.prompt.md](../../.github/prompts/improve-repo.prompt.md). Scheduled execution is a separate, later decision because it requires a credentialed runtime, branch protection, and a proven loop.

## Two Autonomy Levels

| Level | What runs | Status |
| --- | --- | --- |
| Bounded on-demand loop | A human invokes `improve-repo.prompt.md`; the agent runs one iteration end-to-end. | Available now. |
| Scheduled unattended loop | A CI or agent runtime invokes the loop on a schedule or issue assignment. | Deferred until the on-demand loop has a track record. |

## Inputs

- Open GitHub issues labeled `improvement`.
- `checklist.md` when present (local-only and gitignored).
- Failing validation checks and known validation gaps.
- Changelog discrepancies and review findings.
- Friction observed while shipping real application features.

## Role Boundary

`process-improvement` holds `read`, `search`, `edit`, and `todo` but not `execute`. It selects and implements workflow changes. `qa` holds `read`, `search`, `execute`, and `todo` but not `edit`; it runs the focused and umbrella validation and returns evidence. The main chat coordinates the handoff. Do not widen `process-improvement` to include execution just to make the loop feel autonomous.

## Selection Rule

Pick exactly one item, in this order:

1. A failing check or a defect that blocks validation.
2. A review finding with a clear, small fix.
3. A friction point observed while developing an application.
4. A documentation or inventory inconsistency that misleads adopters.

Prefer the smallest diff with the strongest evidence. Reject new agents, skills, framework layers, dependency upgrades, and speculative automation unless a real app-development friction point justifies them.

## Loop

1. Read the baseline instructions and this runbook.
2. Confirm the item is still open and reproducible.
3. Create a feature branch or isolated worktree.
4. Implement the smallest reviewable change with `process-improvement`.
5. Hand off the focused check for the touched surface to `qa`.
6. Hand off the umbrella validation to `qa`.
7. Update `CHANGELOG.md` and `DOC-CHANGELOG.md`.
8. Record a decision trail entry with evidence pointers.
9. Stop with a PR-ready summary, residual risk, and the next candidate.

## Stop Conditions

- Two failed repair attempts on the same item.
- The change crosses a high-risk category in `.github/roles/orchestration-policy.json`.
- The change touches secrets, auth, hooks, MCP, memory policy, approval policy, or dependency trust.
- The diff grows beyond one PR-sized, reviewable change.
- Validation cannot run and no `qa` or human validation path is available.
- No qualifying improvement exists.

## Approval Boundary

The loop may implement and validate low-risk improvements. It must stop for human approval before push, merge, deploy, dependency changes, core-governance changes, security-sensitive changes, or enabling optional high-risk integrations.

## Evidence

Record the commands, exit codes, and relevant results supplied by `qa` or the human operator. Point at artifacts instead of pasting long output. Do not report an unimplemented proposal as completed work.

## Metrics

Track per run:

- improvements completed
- validation pass rate on the first attempt
- repair attempts per item
- human interventions
- reverts or regressions
- app-development friction removed

Use these numbers to decide whether scheduled autonomy is worth building.
