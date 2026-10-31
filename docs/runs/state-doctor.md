# Run state-doctor

- Task: state-doctor — Add a doctor command that checks the workflow wiring instead of assuming it
- Status: DONE
- Final stage: review
- Created: 2026-10-31T21:33:19.648286+00:00
- Updated: 2026-10-31T21:36:11.641535+00:00

## Acceptance criteria

- doctor reports every wiring check with a pass or fail and exits non-zero when a required one fails
- doctor fails when a hook handler points at a script that does not exist
- doctor flags a finished run that was never archived

## Write set

- `.github/scripts/agentic_engine.py`
- `docs/runbooks/agentic-engine.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["cmd:python .github/scripts/agentic_engine.py selftest (116)", "diff:HEAD"], "files": [".github/scripts/agentic_engine.py", "docs/runbooks/agentic-engine.md", "CHANGELOG.md", "DOC-CHANGELOG.md"], "implementedBy": "primary-agent"} |
| 3 | verify | recorded | {"evidence": ["cmd:python .github/scripts/agentic_engine.py selftest", "cmd:python .github/scripts/agentic_engine.py doctor"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:python .github/scripts/agentic_engine.py doctor"], "reviewedBy": "code-reviewer"} |
