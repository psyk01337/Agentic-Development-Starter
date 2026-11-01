# Run runbook-index

- Task: runbook-index — Notice a runbook the index never names
- Status: DONE
- Final stage: review
- Created: 2026-11-01T19:27:28.400479+00:00
- Updated: 2026-11-01T19:32:59.701944+00:00

## Acceptance criteria

- a runbook missing from docs/runbooks/INDEX.md fails the markdown check
- the index itself and an empty runbook directory both pass
- both twins agree on every case and the orphan is listed

## Write set

- `.github/scripts/check-markdown-quality.ps1`
- `.github/scripts/check-markdown-quality.sh`
- `docs/runbooks/INDEX.md`
- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.forlocal/ix-probe/docs/runbooks/INDEX.md`
- `.forlocal/ix-probe/docs/runbooks/agentic-dev.md`
- `.forlocal/ix-probe/docs/runbooks/orphan.md`
- `.forlocal/ix-probe/README.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-markdown-quality.ps1", ".github/scripts/check-markdown-quality.sh", "docs/runbooks/INDEX.md", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-markdown-quality.ps1", "exitCode": 0, "message": "exit 0", "name": "markdown-ps", "ok": true}, {"command": "bash .github/scripts/check-markdown-quality.sh", "exitCode": 0, "message": "exit 0", "name": "markdown-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-markdown-quality.sh"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
