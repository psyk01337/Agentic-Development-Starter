# Run allow-write-directory

- Task: allow-write-directory — Close the window where a write-set entry can become a directory
- Status: DONE
- Final stage: review
- Created: 2026-11-01T20:53:17.684272+00:00
- Updated: 2026-11-01T20:57:19.680513+00:00

## Acceptance criteria

- allow-write refuses a path that contains another write-set entry, even when it does not exist yet
- a legitimate sibling file is still accepted
- the regression test fails without the rule and passes with it

## Write set

- `.github/scripts/agentic_engine.py`
- `docs/runbooks/agentic-engine.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`
- `.github/starter-modules.json`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/agentic_engine.py", "docs/runbooks/agentic-engine.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "senior-software-engineer"} |
| 3 | verify | recorded | {"checks": [{"command": "python .github/scripts/agentic_engine.py selftest", "exitCode": 0, "message": "exit 0", "name": "selftest", "ok": true}], "evidence": ["cmd:python .github/scripts/agentic_engine.py selftest"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "independentEvidence": ["cmd:pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1"], "reviewedBy": "code-reviewer"} |
