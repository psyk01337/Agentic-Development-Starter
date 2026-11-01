# Run app-slice-1

- Task: app-slice-1 — First application slice: a health endpoint with its own test
- Status: DONE
- Final stage: review
- Created: 2026-11-01T20:35:22.432374+00:00
- Updated: 2026-11-01T20:47:10.769388+00:00

## Acceptance criteria

- GET /health returns 200 and a JSON status
- an unknown route returns 404
- the app test command is the one verify executes

## Write set

- `app/package.json`
- `app/src/server.js`
- `app/test/server.test.js`
- `app/README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/scripts/check-manifest-fixtures.sh`
- `.github/scripts/check-manifest-fixtures.ps1`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | allow-write | {"path": "app/src", "reason": "the file paths in the set need their parent directories"} |
| 3 | implement | allow-write | {"path": "app/test", "reason": "the test file needs its parent directory"} |
| 4 | implement | recorded | {"evidence": ["diff:HEAD"], "files": ["app/package.json", "app/src/server.js", "app/test/server.test.js", "app/README.md"], "implementedBy": "senior-software-engineer"} |
| 5 | verify | recorded | {"checks": [{"command": "node --test app/test/server.test.js", "exitCode": 0, "message": "exit 0", "name": "app-tests", "ok": true}], "evidence": ["cmd:node --test app/test/server.test.js"], "result": "VERIFIED"} |
| 6 | review | allow-write | {"path": ".github/scripts/check-manifest-fixtures.sh", "reason": "the app landing exposed that this fixture case assumed an empty app/; it must build the condition"} |
| 7 | review | allow-write | {"path": ".github/scripts/check-manifest-fixtures.ps1", "reason": "same defect and fix in the PowerShell twin"} |
| 8 | review | recorded | {"decision": "needs-revision", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
| 9 | repair | recorded | {"evidence": ["cmd:bash .github/scripts/check-manifest-fixtures.sh"], "files": [".github/scripts/check-manifest-fixtures.sh", ".github/scripts/check-manifest-fixtures.ps1"], "implementedBy": "senior-software-engineer"} |
| 10 | verify | recorded | {"checks": [{"command": "node --test app/test/server.test.js", "exitCode": 0, "message": "exit 0", "name": "app-tests", "ok": true}, {"command": "bash .github/scripts/check-manifest-fixtures.sh", "exitCode": 0, "message": "exit 0", "name": "fixtures-bash", "ok": true}], "evidence": ["cmd:node --test app/test/server.test.js"], "result": "VERIFIED"} |
| 11 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
