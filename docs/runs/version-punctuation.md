# Run version-punctuation

- Task: version-punctuation — Stop the version check punishing punctuation
- Status: DONE
- Final stage: review
- Created: 2026-11-01T18:33:22.549424+00:00
- Updated: 2026-11-01T18:43:48.103197+00:00

## Acceptance criteria

- a Summary line ending at the version passes
- a prerelease or four-part version does not satisfy a three-part manifest version
- both twins agree on every phrasing

## Write set

- `.github/scripts/check-starter-manifest.ps1`
- `.github/scripts/check-starter-manifest.sh`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.forlocal/version-probe/CHANGELOG.md`
- `.forlocal/version-probe/.github/starter-modules.json`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | allow-write | {"path": ".forlocal/version-probe/CHANGELOG.md", "reason": "probe fixture rewritten per test case to exercise the version regex"} |
| 3 | implement | allow-write | {"path": ".forlocal/version-probe/.github/starter-modules.json", "reason": "probe fixture manifest pinned to version 1.0.0 with the maintainer scan off"} |
| 4 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-starter-manifest.ps1", ".github/scripts/check-starter-manifest.sh", ".github/starter-modules.json", "CHANGELOG.md", "DOC-CHANGELOG.md"], "implementedBy": "senior-software-engineer"} |
| 5 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest-ps", "ok": true}, {"command": "bash .github/scripts/check-starter-manifest.sh", "exitCode": 0, "message": "exit 0", "name": "manifest-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-starter-manifest.sh"], "result": "VERIFIED"} |
| 6 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
