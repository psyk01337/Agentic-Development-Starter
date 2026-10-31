# ADR 0009: Govern The Agent Loop With Hooks

- Status: Proposed
- Date: 2026-10-28
- Amended: 2026-10-31 — `agentStop` implemented and verified against a live run; the Agent Host option was investigated and dropped, with the reason recorded. Status stays `Proposed` because whether the host fires `agentStop` is still unobserved.
- Amended: 2026-10-31 — the stop output shape was corrected from the legacy Local form to the top-level `decision`/`reason` shape the Copilot harness reads, and hook configuration was found to be read at session start. See [Amendment: The Stop Contract](#amendment-2026-10-31-the-stop-contract).
- Owners: Team
- Related: `docs/adr/0008-autonomous-execution-via-sdk.md`, `.github/scripts/agentic_engine.py`, `.github/hooks/agent-policy.json`, `.github/roles/tool-access.json`, `docs/runbooks/hooks.md`, `docs/runbooks/agentic-engine.md`

## Amendment (2026-10-31): The Stop Contract

The first `agentStop` implementation could not have worked, for two reasons found after it was written.

**The output shape came from the wrong harness.** The hook emitted `{"hookSpecificOutput": {"hookEventName": "Stop", "decision": "block", "reason": "..."}}`, which is the legacy **Local** harness shape. The Copilot harness reads `decision` and `reason` as **top-level** fields and ignores unsupported ones, so the wrapper would have been dropped and the stop allowed. The engine now emits `{"decision": "block", "reason": "..."}`, and a self-test asserts the top-level shape and the absence of `hookSpecificOutput`.

This is the same failure as the tool vocabulary and the path shape: a format taken from the wrong surface, correct-looking, and untested. Three instances of one class is the finding.

**Hook configuration is read at session start.** A live probe armed a run, ended the turn, and produced no `agentStop` invocation at all. The timestamps settle it: the session started at 11:35, `agentStop` was added to `agent-policy.json` at 13:26, and `postToolUse` was firing normally throughout. The running session held a configuration that predated the event, so the event was never registered.

The operational consequence: **adding, removing, or changing a hook event requires a new session.** Editing `agent-policy.json` mid-session changes nothing. That is why this looked like a platform limitation rather than a stale configuration, and why the first probe attempt was misread.

The event is now instrumented. Every invocation writes one line to `.github/hooks/logs/agent-stop.log`, including when no run is armed. Before that, "the hook never fired" and "the hook fired and its decision was ignored" were indistinguishable from outside.

Status: the decision shape is verified by self-test and by invoking the script directly. Whether the host fires the event is still unobserved, because it could not be observed in the session that added it.

## Context

ADR 0008 concluded that the repository could not execute a loop because nothing could deny a tool call, and proposed the Copilot SDK as the execution substrate. Both halves of that premise turned out to be wrong.

**A deny seam already existed in the host.** A `preToolUse` command hook receives `toolName` and `toolArgs` as JSON on stdin and refuses a call with `{"permissionDecision":"deny"}` or exit `2`. For `preToolUse` the exit contract is fail-closed; only timeouts fail open. The repository already declared such a hook — it had simply never run, because the declaration was outside the harness schema and both scripts read argv instead of stdin. That is fixed separately; the guardrail now fires, and it has since denied live tool calls in this repository.

**The host can also refuse to end a turn.** The `Stop` hook (surfaced as `agentStop`) accepts:

```json
{ "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Run the test suite before finishing."
} }
```

`decision: "block"` prevents the agent execution from stopping and delivers `reason` to the agent. Input carries `stop_hook_active`, true when the agent is already continuing because a previous `Stop` hook blocked it, and the harness stops honouring blocks after eight consecutive ones.

What is still missing is not machinery. The host runs plan → act → observe → retry. What is missing is that the loop is not *this repository's* loop: there is no stage machine, no write set, no budget, and no escalation governing it.

**On the Agent Host.** `code agent host` does expose a first-party headless server, and a Node client can authenticate over its named pipe and complete the AHP handshake. That is recorded in rollout step 5 and deliberately not adopted: creating a session stalls at `lifecycle: "creating"`, so building on it would mean depending on an undocumented initialisation path. The hook seam needs none of it.

## Decision

Govern the host's existing loop with hooks that consult `agentic_engine.py`. Do not build an executor.

| engine stage | host behaviour | enforcement |
|---|---|---|
| `approval` | waits for a human | `preToolUse` denies every `edit` |
| `implement` | writes code | `preToolUse` denies `edit` outside `task.writeSet` |
| `verify` | runs checks | `preToolUse` allows `execute`, denies `edit` |
| `repair` | fixes recorded findings | same as `implement`; `agentStop` refuses to let the turn end |
| `review` | reviews the change | `preToolUse` denies `edit`; `agentStop` requires a decision |
| `done` / `blocked` | stops | `agentStop` allows |

Two hooks carry the whole design:

1. `preToolUse` gates the call: classify the tool from `.github/roles/tool-access.json`, check the stage profile, and check the path against the write set.
2. `agentStop` refuses the turn end while the engine reports an unfinished stage, returning the engine's own `requiredResult` schema as the reason.

`sessionStart` and `postToolUse` remain useful for context injection and audit, but neither is load-bearing for the loop.

The engine already refuses `VERIFIED` while a check fails, refuses a `reviewedBy` that matches an implementer, counts repair attempts, and escalates at `identicalFailureThreshold`. The hook does not reimplement any of it; it asks and relays.

Tool classification reads `toolDefinitions` from `.github/roles/tool-access.json` rather than a private table, because that registry is already the source of truth the supervisor validator checks.

## Consequences

- Positive: the loop becomes governed without a dependency, a credential, a Python version floor, or an optional module. Nothing to install and nothing to buy.
- Positive: with no active run the gate allows everything and calls nothing, so ordinary editing is unaffected in behaviour and in latency.
- Positive: the write set is already derived from git when `changedFilesFrom: "git"`, so an under-reported change cannot satisfy the gate.
- Positive: self-healing needs no new mechanism. The engine already schedules `repair`, and `agentStop` is what makes the agent act on it instead of declaring victory.
- **Blocked turns consume AI credits.** The engine's repair budget and identical-failure stop become the credit bound, and `stop_hook_active` must be honoured so a hook cannot spin forever.
- **Hook configuration is loaded at session start.** Changing `agent-policy.json` mid-session has no effect until a new session begins. A hook that "does not fire" after an edit is stale configuration, not a missing platform feature.
- Risk: `preToolUse` timeouts fail open, so a slow gate protects nothing. An engine gate that *fails* now allows with a warning rather than denying, because a governance control that bricks the editor gets switched off entirely — as happened twice to this guardrail. That means a run's write bounds are unenforced while the engine is unreachable; the rule layer still applies, and the kill switch is documented in `docs/runbooks/hooks.md`.
- Risk: "Sharing a host does not give harnesses a shared hook schema." The hook contract is per-harness, so this design is written against the Copilot harness and must be re-verified before it is claimed for Local or any other runtime. That includes sessions driven over the Agent Host Protocol, where it is unverified.
- Risk: the hook only sees tool calls and turn boundaries, never intent. Planning is governed indirectly through `approval` and the write set; this design never observes a plan and must not claim to verify one.
- Trade-off: the loop is bounded by the host's willingness to honour blocks. After eight consecutive `agentStop` blocks the harness ignores further ones, which is a second stop condition the engine does not control.
- Trade-off: client-contributed tools, including browser and extension tools, require the contributing editor window to stay connected. A windowless run keeps harness tools only, which is enough to run tests but not to drive a browser.

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
2. **Done.** `check-stop` on the engine plus `agent-stop.{sh,ps1}`, registered as the `agentStop` event. The hook returns `{"hookSpecificOutput":{"decision":"block","reason":...}}` while a stage is unfinished and stays silent once `stop_hook_active` is set. Verified against a live run: an `implement` stage produced a block carrying the required result schema, and the same payload with `stop_hook_active: true` produced nothing.
3. **Open.** Confirm the `agentStop` event actually fires in the host. The block output is correct when the script is invoked directly; whether the harness delivers the event has not been observed. This is the difference between a working loop and a correct-looking script.
4. **Open.** `sessionStart` context injection, so the agent starts at the engine's stage instead of discovering it on the first refused turn end.
5. **Dropped.** A standalone client over the Agent Host Protocol. A Node client authenticates and handshakes against the editor host over its named pipe, but `createSession` never progresses past `lifecycle: "creating"` — observed for 180 seconds on an already-authenticated host, with two `session/metaChanged` actions and no further events. The substrate is real; the missing piece is undocumented session initialisation, not something this ADR should depend on.

## Validation

The decision holds only if these are observed:

- With no `.agentic/state`, `pre-tool-policy` and `agent-stop` behave as no-ops and make no engine call.
- With an active run, a write inside the write set is allowed and one outside is denied with the path named.
- With an active run, a write at `verify` is denied regardless of path.
- An unclassified tool name is denied while a run is active, and allowed when none is.
- A finished or blocked run does not restrict anything and does not block a turn end.
- A `preToolUse` caller still receives valid JSON on stdout and exit `2` on every denial.
- An active run blocks the turn end exactly once, and allows it when `stop_hook_active` is set.

Status as of 2026-10-31:

- **Observed.** `python .github/scripts/agentic_engine.py selftest` ran 82 tests, OK, covering the write-set, stage-profile, classification, and stop decisions.
- **Observed.** The hook rule layer denies a command containing a destructive pattern and allows an edit whose *content* mentions it — the defect that forced a maintainer to disable the guardrail.
- **Observed.** `agent-stop.sh` returns the block payload with the required result schema for an active `implement` run, and returns nothing when `stop_hook_active` is true.
- **Observed with a real client.** A `preToolUse` denial was returned to a live tool call twice during this work, once for a probe and once for a cleanup command containing a blocked pattern. The guardrail is live, not merely loadable.
- **Not observed.** That the host fires `agentStop`. Everything above about the stop decision was measured by invoking the script, not by ending a real turn.
- **Not observed.** Any behaviour of these hooks in a session created over the Agent Host Protocol. Rollout step 5 was dropped for that reason.

## Follow-up

Review after rollout step 2. If the gate cannot be shown to behave under a real run, withdraw the `preToolUse` wiring before writing any `agentStop` code, so a partial control is not left looking complete.

Revisit owner: whoever next changes `agentic_engine.py`, `.github/hooks/`, or `.github/roles/tool-access.json`.
