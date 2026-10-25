# Expected Checklist: Decision Trail

- Reads repo baseline instructions and the decision-trail skill before recording anything.
- Records each meaningful decision from the complex task with the suggested fields (timestamp, phase, decision, reason, evidence, result).
- Keeps the suggested fields as guidance rather than enforcing a rigid schema.
- Points evidence at artifacts (test output, commit, file and line, screenshot, trace, browser artifact, benchmark, command output) instead of pasting content.
- Creates no trail artifacts for trivial changes.
- Excludes secrets, credentials, tokens, and raw logs from the trail.
- Does not treat the trail as workflow state or as completion evidence; verification results are produced separately.
- Points at changelog and ADR records instead of duplicating them.
- Reports the trail location, files changed, validation, and residual risk in the handoff.
