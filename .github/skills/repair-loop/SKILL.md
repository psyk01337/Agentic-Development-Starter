---
name: repair-loop
description: Drive the deterministic implement-verify-repair loop with bounded attempts, failure-signature detection, approval gates, and escalation, using the agentic engine as the control plane.
---
# Skill: repair-loop

## When to Use
Use this skill when a task must keep iterating until verification passes, and it must not loop forever. It is the operating procedure for the `agentic_engine.py` control plane.

## Trigger Examples
- "Keep fixing this until the tests pass, with a bounded retry limit."
- "Run the implement-verify-repair loop for this feature and escalate if it repeats."
- "Drive this task through the engine and stop when evidence satisfies the acceptance criteria."

## Canonical Sources
- `.github/roles/orchestration-policy.json` — `retryPolicy`, approval categories, and `evidenceRequirements`.
- `.github/scripts/agentic_engine.py` — the deterministic state machine and its self-tests.
- `docs/runbooks/agentic-engine.md` — command reference and state contract.
- `.github/skills/verification-evidence-loop/SKILL.md` — how to produce `VERIFIED` / `NOT_VERIFIED` / `INCONCLUSIVE`.

## The Loop

```text
init -> approval (when required) -> implement -> verify
                                        |           |
                                        |      VERIFIED -> review -> done
                                        |           |
                                        +------- NOT_VERIFIED -> repair -> verify
                                                    |
                                       identical failure or attempt budget -> blocked
```

`INCONCLUSIVE` retries verification up to `maxVerifyRetries`, then blocks. It is never success.

## Procedure

1. Write the task spec: task id, title, acceptance criteria, declared write set, evidence surfaces, and approval category.
2. Initialize the run with `init`.
3. Ask `next` for the current stage and the required result shape.
4. Do the stage work and record it with `record`.
5. On `verify`, report `VERIFIED`, `NOT_VERIFIED`, or `INCONCLUSIVE` with real evidence pointers and failing checks.
6. On `repair`, fix only the recorded blocking findings and record the repair.
7. Continue until `done` or `blocked`.
8. On `blocked`, escalate with the blocker packet; do not retry manually.

## Rules

- Record evidence from direct observation, not from a summary.
- Keep every changed file inside the declared write set; the engine blocks a violation.
- Do not raise `maxRepairAttempts` to get past a failure; fix the cause or escalate.
- Do not treat `INCONCLUSIVE` as success.
- Do not bypass the approval stage.
- Only the supervisor or the user may declare the task complete, and only when the engine reports `done`.

## Output Format (Strict)
1. Run state
- Run id, stage, status, repair attempts, verify attempts.

2. Current evidence
- The verification entries and the artifacts they point at.

3. Outcome
- `done` or `blocked`, with the blocker reason and packet when blocked.

4. Handoff
- Recommended next agent, inputs, decision status, and approvals needed.
