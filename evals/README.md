# Eval Harness

This directory contains a manual/semi-automated golden-task harness for checking whether agents follow the starter's workflow rules.

The harness does not run real LLMs yet. It gives evaluators task prompts and expected behavior checklists that can be used during manual review, pair evaluation, or future automation.

## Goals

- Confirm agents read repo source-of-truth files before acting.
- Confirm agents keep diffs small and focused.
- Confirm agents update tests, docs, and changelogs when appropriate.
- Confirm agents avoid unsafe commands and disabled-by-default tools.
- Confirm agents produce useful handoffs and memory summaries.

## How To Run

1. Pick a task from `evals/tasks/`.
2. Give the task to the agent in a fresh session.
3. Observe whether the agent inspects the expected repo context first.
4. Score the output with the matching checklist in `evals/expected/`.
5. Record gaps as workflow debt in an issue, ADR, or runbook update.

## Local Structure Check

- Bash: `evals/run-evals.sh`
- PowerShell: `evals/run-evals.ps1`

These scripts verify that the harness files exist and print the available tasks.

## Expansion Path

- Add machine-readable scoring metadata beside each checklist.
- Add fixture repositories for controlled bugfix and feature tasks.
- Add adapters for supported agent platforms.
- Keep any external tools disabled until reviewed.