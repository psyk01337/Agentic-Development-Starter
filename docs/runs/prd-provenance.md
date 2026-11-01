# Run prd-provenance

- Task: prd-provenance — Notice when the PRD names its source but is still a template
- Status: DONE
- Final stage: review
- Created: 2026-11-01T19:02:57.213730+00:00
- Updated: 2026-11-01T19:09:05.701504+00:00

## Acceptance criteria

- a PRD that names a concrete source must contain no template placeholders
- an untouched template PRD, and a PRD with no provenance row, both pass
- a provenance path that does not exist fails, and both twins agree

## Write set

- `.github/scripts/check-starter-manifest.ps1`
- `.github/scripts/check-starter-manifest.sh`
- `docs/prd.md`
- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.forlocal/prd-probe/CHANGELOG.md`
- `.forlocal/prd-probe/.github/starter-modules.json`
- `.forlocal/prd-probe/docs/prd.md`
- `.forlocal/prd-probe/docs/inputs/brief.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-starter-manifest.ps1", ".github/scripts/check-starter-manifest.sh", "docs/prd.md", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest-ps", "ok": true}, {"command": "bash .github/scripts/check-starter-manifest.sh", "exitCode": 0, "message": "exit 0", "name": "manifest-bash", "ok": true}], "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
