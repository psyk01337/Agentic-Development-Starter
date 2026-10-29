# ADR 0009: Govern The Agent Loop With Hooks

- Status: Proposed
- Date: 2026-10-28
- Owners: Team
- Related: `docs/adr/0008-autonomous-execution-via-sdk.md`, `.github/scripts/agentic_engine.py`, `.github/hooks/agent-policy.json`, `.github/roles/tool-access.json`, `docs/runbooks/hooks.md`, `docs/runbooks/agentic-engine.md`

## Context

ADR 0008 concluded that the repository could not execute a loop because nothing could deny a tool call, and proposed the Copilot SDK as the execution substrate. Both halves of that premise turned out to be wrong.

**A deny seam already existed in the host.** A `preToolUse` command hook receives `toolName` and `toolArgs` as JSON on stdin and refuses a call with `{"permissionDecision":"deny"}` or exit `2`. For `preToolUse` the exit contract is fail-closed; only timeouts fail open. The repository already declared such a hook — it had simply never run, because the declaration was outside the harness schema and both scripts read argv instead of stdin. That is fixed separately; the guardrail now fires.

**The host can also refuse to end a turn.** The `Stop` hook (surfaced as `agentStop`) accepts:

```json
{ "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Run the test suite before finishing."
} }
```

`decision: "block"` prevents the agent execution from stopping and delivers `reason` to the agent. Input carries `stop_hook_active`, true when the agent is already continuing because a previous `Stop` hook blocked it.

**A first-party headless host exists.** `code agent host` starts a standalone Agent Host on localhost behind a connection token, and the Agent Host Protocol is an open JSON-RPC protocol with a public source repository. ADR 0008's central justification — that headless execution required an SDK dependency, a Copilot subscription or BYOK key, and a Python 3.11 floor — no longer holds.

What is still missing is not machinery. The host runs plan → act → observe → retry. What is missing is that the loop is not *this repository's* loop: there is no stage machine, no write set, no budget, and no escalation governing it.

## Decision

Govern the host's existing loop with hooks that consult `agentic_engine.py`. Do not build an executor.

| engine stage | host behaviour | enforcement |
|---|---|---|
| `approval` | waits for a human | `preToolUse` denies every `edit` |
| `implement` | writes code | `preToolUse` denies `edit` outside `task.writeSet` |
| `verify` | runs checks | `preToolUse` allows `execute`, denies `edit` |
| `repair` | fixes recorded findings | same as `implement` |
| `review` | reviews the change | `preToolUse` denies `edit`; `agentStop` requires a decision |
| `done` / `blocked` | stops | `agentStop` allows |

Four hooks, no new dependency:

1. `sessionStart` injects `next_payload` — stage, objective, action, `requiredResult` schema, write set — so the agent starts at the engine's stage rather than guessing.
2. `preToolUse` gates the call: classify the tool from `.github/roles/tool-access.json`, check the stage profile, and check the path against the write set.
3. `postToolUse` records verification evidence against the pending run.
4. `agentStop` blocks turn-end while the engine reports an unfinished stage, returning the engine's own `requiredResult` as the reason.

The engine already refuses `VERIFIED` while a check fails, refuses a `reviewedBy` that matches an implementer, counts repair attempts, and escalates at `identicalFailureThreshold`. The hook does not reimplement any of it; it asks and relays.

Tool classification reads `toolDefinitions` from `.github/roles/tool-access.json` rather than a private table, because that registry is already the source of truth the supervisor validator checks.

## Consequences

- Positive: the loop becomes governed without a dependency, a credential, a Python version floor, or an optional module. Nothing to install and nothing to buy.
- Positive: with no active run the gate allows everything and calls nothing, so ordinary editing is unaffected in behaviour and in latency.
- Positive: the write set is already derived from git when `changedFilesFrom: "git"`, so an under-reported change cannot satisfy the gate.
- Trade-off: blocked turns consume AI credits. The engine's repair budget and identical-failure stop become the credit bound, and `stop_hook_active` must be honoured so a hook cannot spin forever.
- Risk: `preToolUse` is fail-closed and timeouts fail open. A slow or broken gate denies every tool call during a run, and a timed-out one protects nothing. The gate must stay well inside the timeout budget.
- Risk: "Sharing a host does not give harnesses a shared hook schema." The hook contract is per-harness, so this design is written against the Copilot harness and must be re-verified before it is claimed for Local or any other runtime.
- Risk: client-contributed tools, including browser and extension tools, require the contributing editor window to stay connected. A windowless run keeps harness tools only, which is enough to run tests but not to drive a browser.
- Trade-off: a hook sees tool calls, not intent. Planning is governed indirectly through `approval` and the write set; this design never observes a plan and must not claim to verify one.

## Options Considered

1. Hooks consulting the engine (chosen)

- Pros: no dependency, fail-closed by contract, runs wherever the agent runs, reuses the tested engine.
- Cons: per-harness contract, cannot drive a stage itself, and blocking turn-end costs credits.

2. Copilot SDK driver (ADR 0008, rejected)

- Pros: a single documented permission handler and a fully owned loop.
- Cons: superseded. The SDK buys headless execution that the Agent Host now provides first-party, at the cost of a dependency, a credential, and a raised Python floor.

3. MCP server exposing engine stages

- Refused. MCP is optional and default-disabled here and `check-mcp-posture` fails on any enabled server, so the capability would vanish in the default configuration.

4. Prompt-only loop

- Refused as enforcement. Nothing stops an agent skipping the engine, so the gates become documentation. Remains the correct default for interactive use.

5. Standalone Agent Host client over AHP

- Deferred, not refused. If a non-VS-Code client can drive a session over AHP, unattended runs become possible without the SDK. Not yet verified, and not required for anything in this ADR.

## Rollout Plan

1. **Done.** `check-tool` on the engine, reading a `preToolUse` payload from stdin, classifying tools from the role registry, and returning a deny decision with exit `2`. Wired into `pre-tool-policy.{sh,ps1}` behind an `.agentic/state` existence check, so it is inert until a run exists.
2. **Open.** Verify the gate against a real run: create a task, record `implement`, and confirm a write outside the write set is refused while a write inside it succeeds. This cannot be established by inspection.
3. **Open.** Probe `agentStop` before implementing it. Confirm that a blocked turn delivers `reason` to the agent, that the agent acts on it, and how `stop_hook_active` behaves across repeated stops. The mechanism is documented; its usefulness is not measured.
4. **Open.** Implement `can-stop` once step 3 passes, with the engine's budget as the credit bound and the run moving to `blocked` rather than blocking forever.
5. **Open.** `sessionStart` context injection, smallest and least risky of the four.

## Validation

The decision holds only if these are observed:

- With no `.agentic/state`, `pre-tool-policy` behaves exactly as before and makes no engine call.
- With an active run, a write inside the write set is allowed and one outside is denied with the path named.
- With an active run, a write at `verify` is denied regardless of path.
- An unclassified tool name is denied while a run is active, and allowed when none is.
- A finished or blocked run does not restrict anything.
- A `preToolUse` caller still receives valid JSON on stdout and exit `2` on every denial.

Status as of 2026-10-28:

- **Engine boundary, observed.** `python .github/scripts/agentic_engine.py selftest` ran 77 tests, OK. Eight `check_tool` cases pass: no active run allows everything, a write inside the set is allowed, a write outside the set is denied, a write at `verify` is denied, `execute` at `verify` is allowed, an unclassified tool is denied during a run, a write with no reported path is denied, and a finished run restricts nothing. The four gate requirements above are therefore observed at the engine boundary rather than assumed.
- **Hook and integration, not run.** `check-hook-policy` and both umbrella suites had not executed against the wiring at the time of writing, so the claim that `pre-tool-policy` still emits valid JSON and exit `2` through the engine path is untested. The wire is inert in this repository because `.agentic/state` does not exist, which is why the gap is tolerable rather than blocking.

## Follow-up

Review after rollout step 2. If the gate cannot be shown to behave under a real run, withdraw the `preToolUse` wiring before writing any `agentStop` code, so a partial control is not left looking complete.

Revisit owner: whoever next changes `agentic_engine.py`, `.github/hooks/`, or `.github/roles/tool-access.json`.
