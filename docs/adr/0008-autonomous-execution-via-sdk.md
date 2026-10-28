# ADR 0008: Autonomous Execution Through The Copilot SDK

- Status: Proposed
- Date: 2026-10-28
- Owners: Team
- Related: `docs/adr/0007-nested-delegation-disabled.md`, `.github/scripts/agentic_engine.py`, `.github/roles/orchestration-policy.json`, `docs/runbooks/agentic-engine.md`, `docs/runbooks/supervisor-orchestration.md`, `README.md`

## Context

The repository has a decision engine and a verification layer, but nothing that executes.

`agentic_engine.py` knows which stage comes next, refuses `VERIFIED` while any check fails, rejects a write outside the declared set, detects a repeated failure signature, and escalates when a budget is spent. Eleven validators produce the evidence those gates consume. Both are tested — 62 engine self-tests plus the contract suites.

What no part of the repository does is call a model, edit a file, or run a test. Today a human drives that, and the engine watches. The loop is real but the muscle is outside the repo.

The obvious way to add muscle is MCP: expose the engine as MCP tools and let the host's agent mode call them. That was the first proposal and it does not survive the repository's own rules. MCP servers are **optional and default-disabled** here, `check-mcp-posture` fails on any `"enabled": true`, and enabling one requires an approval checklist. A capability that only works when an optional, default-off module is switched on is not a core capability. Making it the spine would invert the module model this repository is built on.

Constraints that frame the decision:

- The repository is harness-agnostic by design. Agents and skills are consumed by VS Code agent mode, Copilot, Codex, and anything else that reads `.github/`. A solution that only works in one host weakens that.
- `README.md` states the starter is "not a runtime". Any decision to execute changes that positioning and must be recorded rather than drifted into.
- The engine's gates are only meaningful if something cannot bypass them. A prompt that asks an agent to call the engine is advisory; the permission handler in a driver is not.
- `filesChanged` is currently an **input** to `record`, so a caller can under-report its blast radius. An autonomous loop makes that weakness load-bearing.
- The security baseline requires pinned dependencies, reviewed transitive graph, and no untrusted input reaching a shell. A driver that spawns commands is a new boundary.

## Decision

Adopt the **GitHub Copilot SDK** as the execution substrate, shipped as a **default-disabled optional overlay**, with `agentic_engine.py` acting as the permission handler for every tool call.

The SDK is a library dependency, not an optional service: it is generally available at v1.0.28 under semantic versioning, it bundles the Copilot CLI for Python, Node, and .NET so nothing extra needs installing, it supports custom agents, skills, and tools, and it exposes a **permission handler** that can approve, deny, or customise each tool call.

That handler is the integration point. The driver owns the loop; the engine owns the permission decision:

1. `engine.next()` reports the current stage and the shape of the result it needs.
2. The driver opens an SDK session and lets it work: plan, edit, run commands.
3. Before each tool call, the permission handler asks the engine whether that call is admissible — is the run at a stage where writing is allowed, and does the declared write set contain this path.
4. `filesChanged` is **derived from git**, not accepted from the caller, so the write-set gate cannot be satisfied by an under-report.
5. Verification results are recorded through `engine.record`, which still refuses `VERIFIED` while any check fails.
6. A failing check returns the failure signature to the driver, which re-enters the engine's existing `repair` stage. Self-healing needs no new logic; the repair loop and its identical-failure stop are already implemented and tested.

The overlay is disabled by default because enabling it grants an autonomous process the ability to edit files and run commands. Enabling it is a recorded decision, not a checkbox.

## Consequences

- Positive: the repository gains an executor without acquiring a scheduler, a tool broker, or a queued runtime. The surface added is one driver module and one permission handler.
- Positive: the gates become enforced rather than advisory. A prompt can be ignored; a denied tool call cannot.
- Positive: no MCP dependency, so the capability does not contradict the module model, and no VS Code extension, so the harness-agnostic story survives. The same agents and skills serve interactive and scripted use.
- Positive: the derived-write-set change closes a known weakness in the current engine contract, and would be worth making even if nothing else in this ADR were adopted.
- Trade-off: this makes the repository a runtime in the sense its README denies. That sentence must change in the same change, or the documentation becomes false.
- Trade-off: the SDK requires a Copilot subscription, or BYOK with the user's own provider key, and usage is billed per prompt like the CLI. A driver that retries on failure multiplies cost, and the engine's existing attempt budget is the only thing bounding it.
- Risk: the Node SDK depends on `koffi`, a native FFI binding, alongside `zod` and `vscode-jsonrpc`. The Python SDK avoids that specific surface. Whichever is chosen must be pinned, reviewed, and recorded under the supply-chain rules.
- Risk: a permission handler that is consulted but not obeyed is worse than none, because it looks like a control. The driver must deny by default and treat an unknown tool name as a refusal.
- Risk: autonomous runs produce diffs no human watched. The write set bounds the blast radius but does not judge the change, so review remains required and must not be skipped because the loop reported success.

## Options Considered

1. Copilot SDK driver with engine-mediated permissions (chosen)

- Pros: enforces the existing gates, reuses the tested repair loop, keeps the harness-agnostic story, needs no optional module, and the permission handler is precisely the seam the engine was built for.
- Cons: introduces a runtime and a new dependency, requires a subscription or BYOK, and is the largest behavioural change this repository has considered.

2. MCP server exposing engine stages

- Pros: smallest implementation, reuses the host's loop, and inherits the host's confirmation dialogs.
- Cons: MCP is optional and default-disabled here, so the capability would disappear in the default configuration. `check-mcp-posture` currently forbids enabling a server, so this path also requires weakening a guardrail to work. Refused on that basis.

3. VS Code extension using `vscode.lm`

- Pros: full control of the loop, direct access to editor and terminal APIs, and confirmation dialogs by default.
- Cons: `sendRequest` is a single request and response, so the extension owns planning, tool dispatch, retries, and cancellation — a loop the host already runs correctly. It also works only in VS Code, which forks the agent and skill story. Deferred as a possible ergonomic front end, not as the substrate.

4. Prompt-only loop: instruct the agent to call the engine CLI

- Pros: zero new dependencies and it works today in any host that can run a terminal command.
- Cons: advisory by construction. Nothing stops the agent skipping the engine, so the gates become documentation. Useful as the default interactive path, insufficient as the enforcement mechanism this ADR is about.

5. Do nothing; keep the engine as a passive record

- Pros: no positioning change, no new dependency, no new attack surface.
- Cons: leaves the central gap in place. The repository can describe a bounded loop but cannot run one, and every guarantee it advertises depends on the operator choosing to honour it.

## Rollout Plan

Not authorized by this ADR alone. The sequence, with each step independently revertible:

1. Land the derived-write-set change in the engine, with tests. It is useful on its own and removes a weakness this ADR depends on.
2. Draft the driver behind the overlay, default-disabled, with the permission handler denying unknown tools.
3. Add a validator that asserts the overlay is disabled by default and that the driver denies by default, so the guardrails are contracts rather than intentions.
4. Run one real feature through it in a scratch repository and compare the outcome against the same feature driven interactively.
5. Revise this ADR to `Accepted` only after step 4 produces evidence.

## Validation

The decision is only real if these hold:

- With the overlay disabled, `python .github/scripts/agentic_engine.py selftest` and both umbrella suites pass unchanged, proving no regression to the existing contract.
- A driver test asserts an edit tool call is denied while the run is at `verify`.
- A driver test asserts a write outside the declared set is denied even when the agent reports it as inside.
- A driver test asserts `record --stage verify` with a failing check returns an error rather than advancing the stage.
- A driver test asserts a repeated identical failure reaches the engine's `identical-failure` blocker rather than looping.
- One end-to-end run in a scratch repository produces a diff inside the write set, with changelog entries, and a recorded evidence trail.

## Follow-up

Review after step 4 of the rollout, with the scratch-repository comparison as the input. If the loop cannot be shown to respect the permission handler under adversarial prompting, this ADR moves to `Rejected` and the engine stays a passive record rather than becoming a security theatre.

Revisit owner: whoever next changes `agentic_engine.py` or introduces the overlay.