# Run readme-counts

- Task: readme-counts — Derive the README counts instead of trusting them
- Status: DONE
- Final stage: review
- Created: 2026-11-01T17:45:43.629817+00:00
- Updated: 2026-11-01T18:01:36.562891+00:00

## Acceptance criteria

- check-starter-manifest fails when a README count disagrees with the tree
- check-starter-manifest passes when every derived count matches
- both twins report the same disagreement

## Write set

- `.github/scripts/check-starter-manifest.ps1`
- `.github/scripts/check-starter-manifest.sh`
- `README.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`
- `.github/prompts/initialize-new-project.prompt.md`
- `docs/runbooks/starter-adoption.md`
- `.github/scripts/check-hook-policy.ps1`
- `.github/scripts/check-hook-policy.sh`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | allow-write | {"path": ".github/prompts/initialize-new-project.prompt.md", "reason": "the new README count assertion is gated on maintainerAssetScan, and new projects never flip it"} |
| 3 | implement | allow-write | {"path": "docs/runbooks/starter-adoption.md", "reason": "clone-as-template step 3 must state the same flip or the doc and the prompt disagree"} |
| 4 | implement | allow-write | {"path": ".github/scripts/check-hook-policy.ps1", "reason": "the check is not hermetic; a live run makes the umbrella fail and that blocks validating this run"} |
| 5 | implement | allow-write | {"path": ".github/scripts/check-hook-policy.sh", "reason": "same fix in the bash twin so the pair stays identical"} |
| 6 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/check-starter-manifest.ps1", ".github/scripts/check-starter-manifest.sh", ".github/scripts/check-hook-policy.ps1", ".github/scripts/check-hook-policy.sh", ".github/prompts/initialize-new-project.prompt.md", "docs/runbooks/starter-adoption.md", "README.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 7 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest-powershell", "ok": true}, {"command": "bash .github/scripts/check-starter-manifest.sh", "exitCode": 0, "message": "exit 0", "name": "manifest-bash", "ok": true}], "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1"], "result": "VERIFIED"} |
| 8 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
