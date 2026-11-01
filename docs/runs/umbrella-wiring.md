# Run umbrella-wiring

- Task: umbrella-wiring — Notice a check the umbrella never runs
- Status: DONE
- Final stage: review
- Created: 2026-11-01T19:35:53.770343+00:00
- Updated: 2026-11-01T19:41:22.397532+00:00

## Acceptance criteria

- a check script missing from its twin umbrella fails the manifest check
- the current twelve stay wired in both twins
- both twins agree, and a missing umbrella does not fail

## Write set

- `.github/scripts/check-starter-manifest.ps1`
- `.github/scripts/check-starter-manifest.sh`
- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.forlocal/uw-probe/CHANGELOG.md`
- `.forlocal/uw-probe/.github/starter-modules.json`
- `.forlocal/uw-probe/.github/scripts/check-starter-workflow.ps1`
- `.forlocal/uw-probe/.github/scripts/check-starter-workflow.sh`
- `.forlocal/uw-probe/.github/scripts/check-wired.ps1`
- `.forlocal/uw-probe/.github/scripts/check-wired.sh`
- `.forlocal/uw-probe/.github/scripts/check-loose.ps1`
- `.forlocal/uw-probe/.github/scripts/check-loose.sh`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-starter-manifest.ps1", ".github/scripts/check-starter-manifest.sh", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest-ps", "ok": true}, {"command": "bash .github/scripts/check-starter-manifest.sh", "exitCode": 0, "message": "exit 0", "name": "manifest-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-starter-manifest.sh"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
