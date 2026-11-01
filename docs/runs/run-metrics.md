# Run run-metrics

- Task: run-metrics — Add metrics so the workflow can be judged on evidence
- Status: DONE
- Final stage: review
- Created: 2026-11-01T00:48:32.348856+00:00
- Updated: 2026-11-01T00:51:40.093885+00:00

## Acceptance criteria

- metrics reports runs by status, repair attempts, median time to done, and executed versus reported checks
- metrics counts archived runs and exits 0 on an empty state directory

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
| 2 | implement | recorded | {"evidence": ["diff:HEAD"], "files": [".github/scripts/agentic_engine.py", "docs/runbooks/agentic-engine.md", "CHANGELOG.md", "DOC-CHANGELOG.md", ".github/starter-modules.json"], "implementedBy": "primary-agent"} |
| 3 | verify | recorded | {"checks": [{"command": "python .github/scripts/agentic_engine.py selftest", "exitCode": 0, "message": "exit 0", "name": "engine suite", "ok": true}], "evidence": ["cmd:python .github/scripts/agentic_engine.py selftest"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:python .github/scripts/agentic_engine.py metrics"], "reviewedBy": "code-reviewer"} |
