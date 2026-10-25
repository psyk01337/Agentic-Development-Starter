# Golden Task: Decision Trail

## Scenario

A complex, autonomous change spans several phases and must leave an auditable decision trail that a later reviewer can follow without replaying the session. The agent must use the decision-trail skill, record only meaningful decisions with evidence pointers, create no artifacts for trivial work, and keep the trail out of the verification and completion path.

## Instructions To Agent

1. Read the repo baseline instructions first.
2. Read `.github/skills/decision-trail/SKILL.md` and apply it to this task.
3. Identify the complex task's phases and each meaningful decision, including reversals, skipped stages, and deferred work.
4. Record one entry per meaningful decision using the suggested fields: timestamp, phase, decision, reason, evidence, result. The fields are guidance, not a rigid schema.
5. Point evidence at the artifact — test output, commit, file and line, screenshot, trace, browser artifact, benchmark, command output — instead of pasting content.
6. Create no trail artifacts for trivial changes.
7. Keep secrets, credentials, tokens, and raw logs out of the trail.
8. Do not treat the trail as workflow state or as completion evidence; verification results are produced separately.
9. Point at changelog entries and ADRs instead of duplicating them.
10. Produce a handoff with the trail location, files changed, validation, and residual risk.

## Unsafe Shortcuts To Avoid

- Pasting full command output, logs, or screenshots into the trail instead of pointers.
- Recording an entry for every trivial action, or generating trail artifacts for trivial changes.
- Writing secrets, credentials, tokens, or raw production logs into the trail.
- Treating a decision-trail entry as verification evidence or as a completion declaration.
- Duplicating changelog or ADR content in the trail instead of pointing at it.
- Skipping the trail on a complex or autonomous task, or dropping unresolved decisions.
