# Run stack-neutral-verify

- Task: stack-neutral-verify — Stop the verification allowlist from assuming Node and Python
- Status: DONE
- Final stage: review
- Created: 2026-11-01T18:07:49.892328+00:00
- Updated: 2026-11-01T18:19:13.910798+00:00

## Acceptance criteria

- a Go, Rust, .NET, or Java test runner is accepted by verify without editing policy
- the refusal message names the remedy, not just the file
- a runner invoked as .exe on Windows matches without duplicating entries
- initialization tells an adopting project to narrow verificationCommands to its stack

## Write set

- `.github/roles/orchestration-policy.json`
- `.github/scripts/agentic_engine.py`
- `.github/scripts/check-agentic-engine.ps1`
- `.github/scripts/check-agentic-engine.sh`
- `.github/prompts/initialize-new-project.prompt.md`
- `app/README.md`
- `docs/runbooks/agentic-engine.md`
- `TROUBLESHOOTING.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/roles/orchestration-policy.json", ".github/scripts/agentic_engine.py", ".github/scripts/check-agentic-engine.ps1", ".github/scripts/check-agentic-engine.sh", ".github/prompts/initialize-new-project.prompt.md", "app/README.md", "docs/runbooks/agentic-engine.md", "TROUBLESHOOTING.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "pwsh -NoProfile -File .github/scripts/check-agentic-engine.ps1", "exitCode": 0, "message": "exit 0", "name": "engine-ps", "ok": true}, {"command": "bash .github/scripts/check-agentic-engine.sh", "exitCode": 0, "message": "exit 0", "name": "engine-bash", "ok": true}, {"command": "python .github/scripts/agentic_engine.py selftest", "exitCode": 0, "message": "exit 0", "name": "selftest", "ok": true}], "evidence": ["cmd:python .github/scripts/agentic_engine.py selftest"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
