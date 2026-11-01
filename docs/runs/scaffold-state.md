# Run scaffold-state

- Task: scaffold-state — Notice when the app scaffold still claims to be a scaffold
- Status: DONE
- Final stage: review
- Created: 2026-11-01T18:49:13.399481+00:00
- Updated: 2026-11-01T18:58:18.394920+00:00

## Acceptance criteria

- an app folder holding code but no verification command fails the manifest check
- the starter itself, whose app folder holds only its README, still passes
- both twins agree on every case

## Write set

- `.github/scripts/check-starter-manifest.ps1`
- `.github/scripts/check-starter-manifest.sh`
- `app/README.md`
- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.forlocal/app-probe/README.md`
- `.forlocal/app-probe/.github/starter-modules.json`
- `.forlocal/app-probe/app/README.md`
- `.forlocal/app-probe/app/src/server.js`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-starter-manifest.ps1", ".github/scripts/check-starter-manifest.sh", "app/README.md", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest-ps", "ok": true}, {"command": "bash .github/scripts/check-starter-manifest.sh", "exitCode": 0, "message": "exit 0", "name": "manifest-bash", "ok": true}], "evidence": ["cmd:bash .github/scripts/check-starter-manifest.sh"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
