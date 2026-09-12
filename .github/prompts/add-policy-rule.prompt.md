# Add Policy Rule

Use this prompt to add or adjust a hook policy rule in `.github/hooks/policy-rules.tsv` safely.

## Context To Inspect First

- `.github/hooks/policy-rules.tsv` for existing rules and regex style.
- The "Extending Policy" section of `docs/runbooks/hooks.md` for the required steps.
- `.github/scripts/check-hook-policy.sh` and `.github/scripts/check-hook-policy.ps1` for existing denied and allowed fixtures.

## Deliverables

- One new or adjusted TSV rule with a narrow, PCRE-compatible pattern.
- A concrete reason and a specific safer alternative.
- A denied fixture and at least one allowed counter-example added to both hook policy checkers.
- Changelog and runbook updates when behavior changes.

## Safety Boundaries

- Keep patterns narrow to avoid false positives on common safe commands.
- Do not weaken an existing rule without documented approval.
- Test both Bash and PowerShell checks before merging.
- Stop and ask before destructive changes.

## Expected Output

- Rule added or changed
- Fixtures updated
- Validation run (both shells)
- Residual risks
- Recommended next review step
