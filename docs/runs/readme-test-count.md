# Run readme-test-count

- Task: readme-test-count — Correct the engine-test count the guard just caught
- Status: DONE
- Final stage: review
- Created: 2026-11-01T20:57:42.509245+00:00
- Updated: 2026-11-01T21:04:52.900056+00:00

## Acceptance criteria

- the README badge and prose agree with the 157 tests the suite now runs
- the umbrella passes with the engine fix in place

## Write set

- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": ["README.md", "CHANGELOG.md", "DOC-CHANGELOG.md"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest", "ok": true}], "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
