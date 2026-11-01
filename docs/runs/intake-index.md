# Run intake-index

- Task: intake-index — Notice an intake the repository never acknowledged
- Status: DONE
- Final stage: review
- Created: 2026-11-01T19:16:49.700164+00:00
- Updated: 2026-11-01T19:25:50.741882+00:00

## Acceptance criteria

- a document in docs/inputs/ that the index never mentions fails the manifest check
- the starter, whose inputs folder holds only its README, still passes
- both twins agree on every case

## Write set

- `.github/scripts/check-starter-manifest.ps1`
- `.github/scripts/check-starter-manifest.sh`
- `docs/inputs.md`
- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.forlocal/inputs-probe/CHANGELOG.md`
- `.forlocal/inputs-probe/.github/starter-modules.json`
- `.forlocal/inputs-probe/docs/inputs.md`
- `.forlocal/inputs-probe/docs/inputs/README.md`
- `.forlocal/inputs-probe/docs/inputs/brief.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-starter-manifest.ps1", ".github/scripts/check-starter-manifest.sh", "docs/inputs.md", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest-ps", "ok": true}, {"command": "bash .github/scripts/check-starter-manifest.sh", "exitCode": 0, "message": "exit 0", "name": "manifest-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-starter-manifest.sh"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
