# Agentic Engine Runbook

The agentic engine is the deterministic control plane for multi-step delivery. It turns the team model into a state machine with a bounded repair loop: the host agent does the work, records evidence, and the engine decides whether to continue, repair, or escalate.

It does not call a model. It does not run your tests. It enforces the contract around them.

## Why It Exists

Prompt-only loops degrade in predictable ways: the agent retries the same failing action, declares success without evidence, or loops forever. The engine makes those outcomes impossible to reach silently:

- Every stage records evidence or is rejected.
- Changed files must stay inside the declared write set.
- A repeated failure signature stops the loop instead of retrying it.
- `INCONCLUSIVE` never completes.
- Approval categories block implementation until approved.

## Files

- `.github/scripts/agentic_engine.py` — the engine and its self-tests.
- `.github/scripts/check-agentic-engine.sh` and `.ps1` — policy and engine checks.
- `.github/examples/agentic-engine/simple-feature-task.json` — a task spec example.
- `.github/roles/orchestration-policy.json` — `retryPolicy` is the canonical retry contract.

## State

State is task-scoped and gitignored:

```text
.agentic/state/<run-id>.json
```

Do not commit it. Do not use a single global workflow-state file. The state records the task, stage, attempts, failure signatures, approvals, and full history.

## Commands

All commands accept `--repo-root` and `--state-dir` for tests or non-standard layouts.

```powershell
python .github/scripts/agentic_engine.py init --run-id feature-123 --task task.json
python .github/scripts/agentic_engine.py next --run-id feature-123
python .github/scripts/agentic_engine.py record --run-id feature-123 --stage implement --result implement.json
python .github/scripts/agentic_engine.py record --run-id feature-123 --stage verify --result verify.json
python .github/scripts/agentic_engine.py record --run-id feature-123 --stage repair --result repair.json
python .github/scripts/agentic_engine.py record --run-id feature-123 --stage review --result review.json
python .github/scripts/agentic_engine.py approve --run-id feature-123 --approver alice --note "approved"
python .github/scripts/agentic_engine.py status --run-id feature-123
python .github/scripts/agentic_engine.py report --run-id feature-123
python .github/scripts/agentic_engine.py selftest
```

Exit codes: `0` success, `1` invalid input or transition, `3` blocked or escalated.

## Stage Contract

| Stage | Required result |
| --- | --- |
| `approval` | Use `approve`, not `record`; the task must declare `requestedBy`, and the approver must differ from it |
| `implement` | `status: done`, `filesChanged`, `evidence` |
| `verify` | `result: VERIFIED \| NOT_VERIFIED \| INCONCLUSIVE`, at least one named `check`, `evidence`; `VERIFIED` is refused while any check reports `ok: false` |
| `repair` | `status: done`, `filesChanged`, `evidence` |
| `review` | `decision: pass \| needs-revision`, `findings`, `evidence`; `needs-revision` must name at least one finding |

Every stage requires at least one evidence pointer. A pointer is either a local
path that must exist, or a reference using one of these schemes:
`http://`, `https://`, `cmd:`, `test:`, `commit:`, `diff:`, `trace:`,
`screenshot:`, `benchmark:`, `artifact:`.

The task spec must declare a bounded write set of explicit paths. Wildcards
(`*`, `?`) and the policy's unbounded indicators (`unknown`, `broad`,
`wildcard-only`, `tbd`, `not-safely-bounded`) are rejected at `init`.

Example verification result:

```json
{
  "result": "NOT_VERIFIED",
  "checks": [
    { "name": "pytest tests/test_health.py", "ok": false, "message": "AssertionError: 500 != 200" }
  ],
  "evidence": ["artifacts/pytest-health.log"]
}
```

## Retry Policy

`retryPolicy` in `.github/roles/orchestration-policy.json`:

- `maxRepairAttempts` — repair passes before escalation.
- `identicalFailureThreshold` — how many times the same failure signature may repeat.
- `maxVerifyRetries` — retries for `INCONCLUSIVE`.
- `maxWallClockMinutes` — optional run budget.
- `inconclusiveIsNeverSuccess` — must stay `true`.

The failure signature is always derived from the failing check names and messages (or review findings). A caller-supplied `failureSignature` is used only when there is no structured detail, so a failing agent cannot make each attempt look unique and defeat the identical-failure stop.

Each run is guarded by an advisory lock (`.<run-id>.lock` in the state
directory). A stale lock older than five minutes is reclaimed. `init --force`
refuses to replace a completed run so the audit trail is preserved.

## Blocked Outcomes

The engine blocks with a reason and a packet:

- `identical-failure` — the same failure repeated.
- `attempt-budget-exhausted` — repair limit reached.
- `inconclusive` — verification could not produce evidence.
- `write-set-violation` — changed files outside the declared write set.
- `wall-clock-budget-exceeded` — run budget reached; the run is persisted as
  `BLOCKED` and exits with code `3` on the same call.

A blocked run is not retried by the agent. It is escalated to the user with the packet.

## Using It With The Team

1. The supervisor writes the task spec and declares the write set.
2. `senior-software-engineer` or `tdd-vitest` performs `implement`.
3. `qa` performs `verify` with real evidence.
4. On `NOT_VERIFIED`, the engineer performs `repair`; the engine re-runs `verify`.
5. `code-reviewer` performs `review`.
6. The engine reports `done` only after review passes.

The engine is prompt-level orchestration made deterministic. It cannot stop a host that ignores it, but it cannot itself loop forever, claim success without evidence, or silently leave the write set.

## Self-Tests

The engine ships with its own suite:

```bash
python .github/scripts/agentic_engine.py selftest
```

It covers the happy path, repair-then-success, identical-failure escalation,
attempt-budget escalation, `INCONCLUSIVE`, the approval gate, self-approval
rejection, write-set violation and path normalization, wildcard and unbounded
write sets, missing evidence, bogus evidence pointers, `VERIFIED` with failing
checks, `needs-revision` without findings, wall-clock blocking, `--force` on a
completed run, and state persistence. The umbrella check runs it on every
validation.
