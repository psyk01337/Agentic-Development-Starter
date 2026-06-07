---
name: ci-failure-debugging
description: Triage failing CI from logs to root cause, smallest local fix, and validation evidence.
---
# Skill: ci-failure-debugging

## When to Use
Use this skill when a CI job, workflow step, validation script, or test command fails and the next action is unclear.

## Inputs Expected
- Failing workflow and job name.
- Exact failing command and log excerpt.
- Recent diff or relevant changed files.
- Local reproduction command, if known.
- Required environment assumptions or secrets availability.

## Procedure
1. Identify the failing step, command, and first meaningful error.
2. Separate environment failure from repo-local failure.
3. Form one falsifiable local hypothesis and one cheap disconfirming check.
4. Fix the smallest local cause when evidence supports it.
5. Re-run the closest validation command or record why it cannot be run.

## Output Format
- Failure summary
- Likely cause
- Evidence
- Fix or recommended fix
- Validation run
- Remaining risk

## Verification Checklist
- The failing command and error are quoted or summarized accurately.
- The proposed fix does not disable checks, loosen security, or hide failures.
- The validation command matches the failing slice.
- Environmental blockers are called out explicitly.

## Safety Notes
- Do not edit secrets, deployment credentials, or protected environments from CI logs.
- Do not silence tests or make workflows non-blocking without explicit approval.
- Stop and ask before destructive changes.

## Referenced Scripts Or Resources
- `.github/workflows/`
- `.github/scripts/check-starter-workflow.sh`
- `.github/scripts/check-starter-workflow.ps1`
- `.github/prompts/debug-failing-ci.prompt.md`