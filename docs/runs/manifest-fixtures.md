# Run manifest-fixtures

- Task: manifest-fixtures — Give the manifest check a fixture harness so its rules are tested
- Status: DONE
- Final stage: review
- Created: 2026-11-01T19:42:51.751620+00:00
- Updated: 2026-11-01T19:54:25.687837+00:00

## Acceptance criteria

- each self-description rule fails a case in the harness when broken
- the harness passes on the untouched repository
- the new check is wired into both umbrellas and registered

## Write set

- `.github/scripts/check-manifest-fixtures.ps1`
- `.github/scripts/check-manifest-fixtures.sh`
- `.github/scripts/check-starter-workflow.ps1`
- `.github/scripts/check-starter-workflow.sh`
- `.github/starter-modules.json`
- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `docs/runbooks/module-manifest-versioning.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-manifest-fixtures.ps1", ".github/scripts/check-manifest-fixtures.sh", ".github/scripts/check-starter-workflow.ps1", ".github/scripts/check-starter-workflow.sh", ".github/starter-modules.json", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", "docs/runbooks/module-manifest-versioning.md"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-manifest-fixtures.ps1", "exitCode": 0, "message": "exit 0", "name": "fixtures-ps", "ok": true}, {"command": "bash .github/scripts/check-manifest-fixtures.sh", "exitCode": 0, "message": "exit 0", "name": "fixtures-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-manifest-fixtures.sh"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
