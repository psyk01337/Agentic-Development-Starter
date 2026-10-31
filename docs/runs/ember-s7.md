# Run ember-s7

- Task: ember-s7 — Route all input through one tested decision, and stop auto-repeat from restarting a run
- Status: DONE
- Final stage: review
- Created: 2026-10-31T20:52:36.348072+00:00
- Updated: 2026-10-31T20:56:31.104501+00:00

## Acceptance criteria

- Every jump gesture (Space, ArrowUp, pointerdown, touchstart) resolves through a single pure function that the test suite covers
- A held Space key auto-repeat cannot restart a finished run; restart needs a fresh press
- The full game suite passes and the shipped payload stays under the 500 KB budget

## Write set

- `app/game/src/input.js`
- `app/game/tests/input.test.mjs`
- `app/game/src/main.js`
- `docs/prd.md`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`

## History

| # | stage | action | detail |
| --- | --- | --- | --- |
| 1 | implement | init | {"detail": "run initialized"} |
| 2 | implement | recorded | {"evidence": ["cmd:node --test (78 passing)", "diff:HEAD"], "files": ["app/game/src/input.js", "app/game/tests/input.test.mjs", "app/game/src/main.js", "docs/prd.md", "CHANGELOG.md", "DOC-CHANGELOG.md"], "implementedBy": "primary-agent"} |
| 3 | verify | recorded | {"evidence": ["cmd:node --test", "cmd:node --check src/main.js"], "result": "VERIFIED"} |
| 4 | review | recorded | {"decision": "pass", "evidence": ["cmd:node --test"], "reviewedBy": "code-reviewer"} |
