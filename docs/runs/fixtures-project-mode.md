# Run fixtures-project-mode

- Task: fixtures-project-mode — Make the fixture harness work in project mode
- Status: DONE
- Final stage: review
- Created: 2026-11-01T21:34:12.984967+00:00
- Updated: 2026-11-01T21:43:28.760294+00:00

## Acceptance criteria

- a freshly initialized project skips the starter-only case instead of failing
- the starter still runs all seven cases
- both twins agree

## Write set

- `.github/scripts/check-manifest-fixtures.ps1`
- `.github/scripts/check-manifest-fixtures.sh`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-manifest-fixtures.ps1", ".github/scripts/check-manifest-fixtures.sh", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-manifest-fixtures.ps1", "exitCode": 0, "message": "exit 0", "name": "fixtures-ps", "ok": true}, {"command": "bash .github/scripts/check-manifest-fixtures.sh", "exitCode": 0, "message": "exit 0", "name": "fixtures-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-manifest-fixtures.sh"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
