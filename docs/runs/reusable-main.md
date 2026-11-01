# Run reusable-main

- Task: reusable-main — Make a freshly cloned project actually reusable
- Status: DONE
- Final stage: review
- Created: 2026-11-01T21:47:45.863557+00:00
- Updated: 2026-11-01T21:52:13.509677+00:00

## Acceptance criteria

- the documented init produces a main branch so CI can trigger
- initialization says why the branch name matters
- the guidance is consistent across quickstart, runbook, and prompt

## Write set

- `QUICKSTART.md`
- `docs/runbooks/starter-adoption.md`
- `.github/prompts/initialize-new-project.prompt.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": ["QUICKSTART.md", "docs/runbooks/starter-adoption.md", ".github/prompts/initialize-new-project.prompt.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1", "exitCode": 0, "message": "exit 0", "name": "manifest", "ok": true}], "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-manifest.ps1"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
