# Autonomous Execution Runbook

The optional overlay that lets a process run the implement-verify-repair loop itself, with `agentic_engine.py` deciding what it is allowed to do.

Disabled by default. `docs/adr/0008-autonomous-execution-via-sdk.md` records the decision and its rejected alternatives.

## What It Is And Is Not

It is a **driver**: something owns the outer loop, asks the engine what stage is required, lets an executor work that stage, records the result, and repeats until the engine reports done or blocked.

It is **not** a sandbox. The permission gateway decides whether a tool call is admissible; it does not contain the call. A tool that is permitted at `implement` runs with the permissions of the process that invoked it. Treat enabling this overlay as granting an autonomous process the ability to edit files and run commands in that repository.

## The Split

| Concern | Owner |
| --- | --- |
| Which stage is next | `agentic_engine.py` |
| Whether a tool call is admissible | `PermissionGateway` in `agentic_driver.py` |
| Doing the work | an executor, for example the Copilot SDK |
| Whether evidence is sufficient | `agentic_engine.py` |
| When to stop repairing | `agentic_engine.py` retry policy |

Nothing about the loop is decided by the executor. That is the point.

## Stage Permissions

Each stage gets a fresh gateway, because what is permitted changes with the stage.

| Stage | read | run | write |
| --- | --- | --- | --- |
| `approval` | yes | no | no |
| `implement` | yes | yes | yes |
| `repair` | yes | yes | yes |
| `verify` | yes | yes | no |
| `review` | yes | yes | no |
| `blocked` | yes | no | no |
| `done` | yes | no | no |

Verification that edits files is not verification, so `verify` cannot write. Review cannot write for the same reason.

## Deny By Default

Three rules make the gateway a control rather than a suggestion:

1. **Unclassified tools are denied.** The tool-to-kind map is explicit. Inferring a kind from a tool name would let a rename bypass the stage check.
2. **Unknown stages cannot construct a gateway.** `PermissionGateway` raises rather than falling back to a permissive default.
3. **A write must name its path and stay inside the declared write set.** A write tool that omits `path` is denied rather than assumed benign.

Denials are retained on the gateway and surfaced by `run_loop`, so a caller can act on them. A denial that is silently swallowed is worse than no check, because it looks like enforcement.

## Deriving The Write Set From Git

`agentic_engine.py` normally trusts the `filesChanged` a caller reports. A task can instead set:

```json
"changedFilesFrom": "git"
```

Then the engine reads `git status --porcelain` in the repository and uses that as the authoritative changed set, so an under-reported `filesChanged` cannot satisfy the write-set gate. Files the caller declared but git does not report are ignored, and the fact is recorded in history.

Two consequences to plan for:

- The check fails closed. If git cannot answer, the record is refused rather than treated as "nothing changed".
- Task specs and result files must not appear as repository changes. Keep them outside the work tree, or ignore them, or they will be reported as out-of-scope writes.

## Wiring An Executor

`Executor` is the seam. Implement `run_stage(stage, payload, gateway)` and consult `gateway.evaluate()` before every tool call:

```python
decision = gateway.evaluate("write_file", {"path": "src/api.py"})
if not decision.allowed:
    return StageResult({"status": "blocked", "reason": decision.reason})
```

`ScriptedExecutor` replays canned results and is what the self-tests use. `CopilotSdkExecutor` raises an explicit error: the adapter is not wired, because the SDK is an optional dependency that needs Copilot credentials or a BYOK key that this repository does not carry. A missing adapter must never look like a working loop.

## Checking It

```bash
bash .github/scripts/check-agentic-driver.sh
```

```powershell
pwsh -NoProfile -File .github/scripts/check-agentic-driver.ps1
```

The check runs the driver self-tests and asserts that the overlay ships disabled and that the gateway still denies unclassified tools. Those three assertions are the contract; loosening any of them is a change to this runbook, not just to a script.

## Enabling It

1. Read `docs/adr/0008-autonomous-execution-via-sdk.md`.
2. Set the module to enabled in your own copy of `.github/starter-modules.json` and record the decision in your `CHANGELOG.md`.
3. Run one feature through it and compare the result with the same feature driven interactively.
4. Keep `changedFilesFrom: "git"` on every task. Without it the write-set gate is only as good as the executor's honesty.

## Known Gaps

- The SDK adapter is unimplemented. Everything above it is tested; the adapter is not.
- The gateway bounds scope, not judgment. A change inside the write set can still be wrong, so review is still required and must not be skipped because the loop said done.
- Command execution is guarded against shell metacharacters, not sandboxed. A permitted command runs with the invoking process's permissions.
- Reviewer separation remains a string comparison in the engine. In a single-process autonomous run one actor can satisfy it by writing both names, which is why the review stage is not a substitute for a human.