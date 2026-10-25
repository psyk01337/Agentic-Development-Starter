---
name: verification-evidence-loop
description: Optional overlay skill that determines the required verification evidence for each touched change surface, gathers VERIFIED / NOT_VERIFIED / INCONCLUSIVE results from direct observation, and emits delegation-result-schema-shaped verification entries for the supervisor orchestration overlay.
---
# Skill: verification-evidence-loop

## When to Use
Use this skill when the repo has enabled `overlay-supervisor-orchestration` and a change must be verified against its success predicate before the orchestrator declares completion. The completion invariant is: no agent may mark work complete; only the orchestrator declares completion after verification evidence satisfies the success predicate.

Do not use it to declare task completion; that is the orchestrator's job under the completion rule in the policy. Do not treat a well-formed result as proof; evidence must point at observable artifacts.

## Trigger Examples
- "Verify the changed admin flow and produce the verification record."
- "Run the verification-evidence loop for this API change."
- "Collect direct verification evidence for this bugfix before handoff."

## Canonical Sources
- `.github/roles/orchestration-policy.json` — `evidenceRequirements` is the canonical source for the result vocabulary, the completion rule, and the per-surface evidence kinds.
- `.github/schema/delegation-result.schema.json` — the contract this skill's verification entries feed.
- `docs/runbooks/supervisor-orchestration.md` — the overlay operating model.

## Checklist
- Name the change surface first: `ui`, `api`, `database`, `cli`, `configuration`, or `library`. A change may touch several; verify each touched surface.
- Read the required evidence kinds for the surface from `evidenceRequirements.surfaces` in the policy; do not substitute a summary for direct observation.
- Exercise the real artifact where practical: run the UI, execute the endpoint, apply the migration to disposable data, run the command, load the configuration with the real parser, or test the public interface through callers.
- For a bug fix: reproduce the bug before the fix when reasonably possible, preserve the reproduction as a regression test or deterministic check, and prove the reproduction no longer fails afterward.
- Record each verification as `surface`, `method`, `result`, and `evidenceReference`, with `result` restricted to the policy vocabulary: `VERIFIED`, `NOT_VERIFIED`, or `INCONCLUSIVE`.
- `INCONCLUSIVE` is never a success and never satisfies a success predicate; do not round it up.
- Point evidence at observable artifacts — command output, test output, screenshots, read-back state — rather than agent self-reports.
- Emit verification entries shaped by `.github/schema/delegation-result.schema.json` (the `verificationPerformed` array) so the supervisor can reconcile from fields.

## Output Format (Strict)
Produce sections in this exact order:

1. Change Surface
- One line per touched surface with its evidence kinds from the policy.

2. Verification Performed
- One entry per check: `surface`, `method`, `result` (`VERIFIED` / `NOT_VERIFIED` / `INCONCLUSIVE`), `evidenceReference`.

3. Evidence
- Pointers to observable artifacts, not restated claims.

4. Residual Verification Debt
- What was not measured, which paths or environments remain unverified, and any `INCONCLUSIVE` results that block success.