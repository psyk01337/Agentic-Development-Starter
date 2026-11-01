# Run family-guard-fixture

- Task: family-guard-fixture — Test the family guard that protects stack neutrality
- Status: DONE
- Final stage: review
- Created: 2026-11-01T19:56:27.931068+00:00
- Updated: 2026-11-01T20:12:01.890596+00:00

## Acceptance criteria

- trimming verificationCommands in a copied tree fails check-agentic-engine
- the fixture cannot recurse into the copied check
- the real repository still passes both twins

## Write set

- `.github/scripts/check-agentic-engine.ps1`
- `.github/scripts/check-agentic-engine.sh`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.github/scripts/check-starter-manifest.ps1`
- `.github/scripts/check-starter-manifest.sh`
- `.github/scripts/check-manifest-fixtures.ps1`
- `.github/scripts/check-manifest-fixtures.sh`
- `README.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | allow-write | {"path": ".github/scripts/check-starter-manifest.ps1", "reason": "an empty check script exits 0 and the umbrella reports green; the size rule belongs with the other wiring rules"} |
| 3 | implement | allow-write | {"path": ".github/scripts/check-starter-manifest.sh", "reason": "same rule in the bash twin"} |
| 4 | implement | allow-write | {"path": ".github/scripts/check-manifest-fixtures.ps1", "reason": "every new rule gets a fixture case, per the discipline established last change"} |
| 5 | implement | allow-write | {"path": ".github/scripts/check-manifest-fixtures.sh", "reason": "same case in the bash twin"} |
| 6 | implement | allow-write | {"path": "README.md", "reason": "the check table is the only place the empty-script catch is described"} |
| 7 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-agentic-engine.ps1", ".github/scripts/check-agentic-engine.sh", ".github/scripts/check-starter-manifest.ps1", ".github/scripts/check-starter-manifest.sh", ".github/scripts/check-manifest-fixtures.ps1", ".github/scripts/check-manifest-fixtures.sh", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 8 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-agentic-engine.ps1", "exitCode": 0, "message": "exit 0", "name": "engine-ps", "ok": true}, {"command": "bash .github/scripts/check-agentic-engine.sh", "exitCode": 0, "message": "exit 0", "name": "engine-bash", "ok": true}, {"command": "bash .github/scripts/check-manifest-fixtures.sh", "exitCode": 0, "message": "exit 0", "name": "fixtures-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-manifest-fixtures.sh"], "result": "VERIFIED"} |
| 9 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
