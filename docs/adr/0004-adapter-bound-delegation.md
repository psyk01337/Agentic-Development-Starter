# ADR 0004: Adapter-Bound Delegation and the Orchestration Role Model

- Status: Accepted
- Date: 2026-09-14
- Approved: 2026-09-14 by the repository maintainer (user), recorded as the required approval for a `core-governance-change`
- Owners: Team
- Related: `docs/adr/0001-approval-gated-orchestration-overlay.md`, `docs/adr/0003-supervisor-orchestration-overlay.md`, `.github/agent-catalog.md`, `.github/roles/tool-access.json`, `.github/roles/orchestration-policy.json`, `.github/agents/delegation-supervisor.agent.md`, `.github/agents/orchestration-coordinator.agent.md`, `.github/scripts/check-supervisor-orchestration.sh`, `.github/scripts/check-supervisor-orchestration.ps1`, `docs/runbooks/supervisor-orchestration.md`

## Context

ADR 0003 named `delegate-agent` as an abstract capability and made `delegation-supervisor` its sole holder. `.github/roles/tool-access.json` v1.2 carries that capability in `toolDefinitions`, and its `examples` field records how the abstraction is meant to reach a runtime:

> platform-mapped, not a literal tool name: VS Code agent/runSubagent; other runtimes use their own delegation primitive

The validator does not implement that sentence. It does the opposite. `check-supervisor-orchestration.sh` fixes `expected_role_tools` to `{"read", "search", "todo", "delegate-agent"}`, requires the `orchestration` role's tool list to equal it exactly, and requires `delegation-supervisor` frontmatter to equal it exactly as well. A host tool name on the supervisor is therefore an "extra tool" error, and the same name on any other agent is a sole-holder violation. The mapping the capability definition promises cannot be declared by any agent file.

Three consequences follow, and they are the reason this ADR exists.

1. The overlay's headline capability is inert as shipped. `delegation-supervisor.agent.md` declares `tools: [read, search, todo, delegate-agent]` and no `agents` key. It holds a capability it cannot exercise, and the check that would notice the difference reads only this repository's abstract name.
2. The rule that guards the dangerous case does not exist. `agents:` without a host tool is a dead declaration: the allow-list is validated while nothing can invoke it. A host tool without `agents:` is unscoped delegation. The validator rejects neither, because it expects the tool to be absent.
3. `orchestration-coordinator` is half-registered. It declares `tools: [read, search, todo]`, appears in `.github/agent-catalog.md` and in `starter-modules.json`, and has no `agentCapabilityMatrix` entry and no `agentRoleHints` entry. `README.md` states that registering an agent means registering it in both places, so a shipped asset contradicts a stated rule. Nothing catches it: the matrix scan iterates `agentCapabilityMatrix` and compares it against agent files, so an agent file with no matrix entry is never reached, and the role-hint check is skipped whenever the matrix lookup returns nothing.

The missing registration is not an oversight that a single row would fix, but the reason is semantic rather than structural. `orchestration-coordinator` declares exactly `read`, `search`, and `todo`, and the `review` role carries that identical tool set, so a slot with matching capabilities does exist. What does not exist is a slot with matching purpose. The `review` role's stated intent is to inspect work and report findings against repo standards, which is what `architecture-reviewer`, `code-reviewer`, and `security-reviewer` do; registering a workflow-transition coordinator under it would make the registry assert a function the agent does not perform and would dilute a term three agents already share. The coordinator's distinguishing authority is that it recommends a transition for a human to approve without invoking anything, which no existing role describes.

An earlier version of this paragraph claimed that no role in `tool-access.json` carried the coordinator's tool set, having compared only `analysis` and `workflow-maintenance`. That claim was incomplete: `review` was not checked and matches exactly. The claim is corrected here. The decision is unchanged, because it rests on the purpose a role records rather than on whether a role with the same capabilities exists.

A second hardcoded list compounds the problem. Both validator twins embed the platform delegation vocabulary as a literal, currently `agent` and `runSubagent`. The set is not derived from anything and is not tied to the host it describes, so a host whose delegation primitive has a different name is outside the rule by construction.

The alternative readings are both closed by existing contract. Promoting a third `orchestrator` agent into core is refused by the Deliberate Exclusions in `agent-catalog.md`, which permit supervised delegation only through the default-disabled `overlay-supervisor-orchestration` overlay under the canonical policy in `orchestration-policy.json`. Merging the coordinator and the supervisor into one control plane is refused by `delegation-supervisor.agent.md` itself, which states "Do not merge these roles," and by ADR 0003's Decision.

## Decision

Bring the enforcement layer into line with the contract it already ships, and close the two registry defects that contract exposes.

`delegate-agent` remains the single canonical capability name and stays platform-mapped. The validator stops comparing tool sets by exact equality over the abstract name and instead asserts four properties: the holder's frontmatter must contain the canonical capability; it may additionally contain tool names that the host adapter map declares for that capability; it may contain nothing else; and `edit` and `execute` stay forbidden on the `orchestration` role. Exactly one agent may hold the capability and exactly one may hold the mapped host tool, which preserves ADR 0003's sole-holder rule over the host's vocabulary as well as this repository's.

The host adapter map lives in `.github/roles/orchestration-policy.json` under `delegationDepth`, keyed by host. That file is already the canonical single source for the delegation depth, the capability name, and the specialist allow-list, and it is scoped to `overlay-supervisor-orchestration`, so host-specific tool names do not enter `tool-access.json`, which is core and present in every adopting repo. The map becomes the source for the delegation vocabulary, replacing the literal `agent` and `runSubagent` list in both validator twins, so a host with a differently named primitive is covered by data rather than by a code change.

Two pairing rules replace the current blanket prohibition. Declaring an `agents` allow-list requires declaring the host delegation tool for that host, because a validated allow-list nothing can invoke is a guardrail in appearance only. Declaring the host delegation tool requires declaring `agents`, because an invocation path without a validated allow-list is the unscoped case. Where `agents` is declared, its entries must stay within the canonical `specialistAllowList`, as today.

The role vocabulary gains one entry. A new `advisory` role holds `read`, `search`, and `todo` and maps to the non-mutating tier's predicate. `orchestration-coordinator` is registered against it in both `agentRoleHints` and `agentCapabilityMatrix`, and its role string in `.github/agent-catalog.md` is aligned to the vocabulary. The role describes an authority level rather than a tier, because tier membership stays derived from frontmatter.

Registration becomes checkable in the direction that matters: **every agent file not on the specialist allow-list must have an `agentCapabilityMatrix` entry and an `agentRoleHints` entry.** The tolerance for an allow-listed non-mutating agent without a matrix entry is preserved deliberately and unchanged, because the non-mutating tier derives from frontmatter and an absent matrix entry cannot shrink it. That reasoning holds only for allow-listed agents. An agent off the allow-list has nothing deriving anything from it, so its declared tools are covered by no rule at all when its matrix entry is missing, which is precisely the coordinator's state.

`handoffs` is classified explicitly and is not a delegation path. It renders a transition a human selects, so it is the host's form of the guided handoff the core model already sanctions, and it may appear on any agent. No validator scans it, and this ADR does not add one; the classification is recorded here so that the asymmetry between `agents` and `handoffs` is stated rather than inferred.

Routing policy stays data. Task classes, playbooks, and evidence requirements belong in `.github/roles/orchestration-policy.json`, not in prose inside an agent file, because a table can be pinned by negative fixtures and prose cannot. This ADR does not add those keys; it fixes the capability model they would depend on.

The two agents are not merged and no core orchestrator is created. `delegation-supervisor` remains the only agent that classifies a task into a playbook and acts on it. `orchestration-coordinator` remains advisory: it recommends a transition for human approval, requires approval, and falls back when approval is absent. It never invokes anything, and its `[read, search, todo]` declaration already satisfies that. If the coordinator proves vestigial once routing policy exists as data, deprecating it is a separate decision with usage evidence, not part of this change.

The gate remains a prompt-level contract, not enforcement. This ADR adds no identity source, no enforcement point, and no hook seam for agent-to-agent delegation, and no documentation may describe the gate as enforced authorization.

ADR 0003 is `Accepted` and is not edited by this ADR. This ADR amends its implementation by changing the `orchestration` role's tool set and the rule that compares it. The amendment pointer in ADR 0003 is added in the same change that lands the implementation and its recorded approval.

## Consequences

Positive outcomes

- The capability definition in `tool-access.json` becomes true. Its prose claim and the machine-readable rule finally describe the same thing.
- The pairing rules close the two silent states the current rule cannot see: an allow-list nothing can invoke, and an invocation path with no scope.
- The delegation vocabulary becomes data. Adding a host no longer requires editing two validator twins in parallel, which is the drift class that has already produced two parsing defects in these files.
- `orchestration-coordinator` stops being a shipped asset that contradicts a documented registration rule, and the repository gains the role its own non-mutating tier concept implies.
- The registration rule closes the reverse direction for the agents where an absent matrix entry actually removes coverage, without disturbing the tolerance that a positive fixture pins.

Trade-offs and risks

- The rule shape weakens from exact set equality to contains-plus-explicit-allow-list. That is a genuinely weaker form, and it is only safe if the allow-list is closed. Adapter values must be validated against the map and rejected when they resolve to a mutating capability; a permissive map would become a laundering route for privileged tool names. This is the main risk this ADR introduces.
- Delegation is transitively privileged. The allow-list includes agents that hold `edit` and `execute`, so the supervisor's authority is real even though its own declaration is not. The delegation boundary, not the supervisor role, is the security-relevant surface, and the one-level depth limit is what keeps it bounded.
- The host adapter set is unverified. The current literal includes `agent` and `runSubagent`; only `agent` was confirmed against host documentation. Landing the map requires confirming which names are live for each host and recording `unsupported` where none is, rather than carrying an inherited guess forward as data.
- The pairing rule is stricter than today, so a repo that ships `agents` without the host tool goes red. That is the intended detection of the dead-declaration case, and it must be described as such rather than as a regression.
- A new role term enters the vocabulary. `advisory` is one more name a reader must hold, and the alternative of bending the coordinator into a mismatched role trades that cost for a false statement in the registry.
- Host-specific tool names now appear in `orchestration-policy.json`. That keeps them out of a core file, but it does put vendor vocabulary in the file that is otherwise host-neutral, so the map must stay clearly scoped as adapter data.

Operational impacts

- `tool-access.json` and `agent-catalog.md` are approval-protected. The change is a `core-governance-change` and needs recorded maintainer approval before merge.
- The supervisor's frontmatter, the adapter allowance, and the pairing rules must land in a single change. Landing the pairing rules first turns the shipped tree red; landing the frontmatter first fails the current exact-equality rule.
- Both validator twins change together, with negative fixtures per platform, and both must remain registered in the paired workflow entry points or they never run.
- `docs/runbooks/supervisor-orchestration.md` and ADR 0003's amendment pointer are updated in the same change, so no design document describes a rule the code does not assert.

## Options Considered

1. Status quo: abstract capability, host tools forbidden

- Pros
- No change, no new failure surface
- The sole-holder rule stays a single simple comparison

- Cons
- The capability definition's stated mapping stays false, and the rule actively prevents it
- The overlay's headline capability remains inert as shipped
- Neither the dead-declaration case nor the unscoped-invocation case is guarded

1. Host-native only: drop the abstraction and declare real tool names

- Pros
- Every declaration maps to something a runtime can execute
- No adapter layer and no mapping to maintain

- Cons
- Destroys portability, which is the reason this repository is host-neutral at all
- `delegate-agent` disappears from `tool-access.json`, `orchestration-policy.json`, and the agent catalog, and with it the ability to state the invariant without naming a vendor
- Reintroduces the vendor coupling the tool-surface matrix exists to avoid

1. Adapter-bound capability with a single holder, adopted here

- Pros
- Makes the shipped contract true without adding an abstraction the repo does not already declare
- Keeps the invariant expressible host-neutrally while allowing each host to be described concretely
- Removes the second hardcoded list rather than extending it
- Binds a capability to a runtime in a way a validator can assert

- Cons
- Adds a mapping layer and a new failure surface, which must be closed rather than permissive
- Requires the frontmatter, the map, and the rules to land atomically
- Puts host tool names into the policy file

1. Per-host agent files or per-host role variants

- Pros
- Each host file can carry exactly the tools that host provides
- No mapping indirection at runtime

- Cons
- Duplicates governance that must then be kept aligned across files, which is the drift class already observed twice in these same validators
- `agent-catalog.md` and the capability matrix would need per-host registration, multiplying the registry instead of the one place it is checked
- The distinction is in tool naming, not in semantics, so the cost buys nothing the adapter map does not

1. Script-driven invoker in place of host delegation

- Pros
- Works identically on hosts that provide no delegation primitive
- Fully deterministic and testable without a host

- Cons
- ADR 0001 refuses a core runtime orchestration engine, and the overlay depends on that refusal
- Builds shell automation for something the host already provides, which the vNext design rules exclude
- Creates a second execution path outside `preToolUse`, weakening the only mechanical guardrail this starter has

1. Consolidate the coordinator into the supervisor as one control plane

- Pros
- One authority for "what happens next" instead of two
- Removes a role-registration problem by removing the agent

- Cons
- `delegation-supervisor.agent.md` states "Do not merge these roles", and ADR 0003 repeats it, so this reverses an accepted decision
- Breaks a shipped overlay, its validator, its runbook, and its adoption path for adopters already referencing it
- The two serve different actors, human-approved transitions and machine delegation, so the merge conflates an authority level with a capability
- Removes the option of separating them later, which is available and cheap while they remain distinct

1. Add a core `orchestrator` agent

- Pros
- Matches the vNext prompt's Phase 1 wording most directly
- Would give routing one obvious owner

- Cons
- Refused by the `agent-catalog.md` Deliberate Exclusions, which permit supervised delegation only through the default-disabled overlay
- Creates a third orchestration authority alongside two that already overlap
- Puts automatic orchestration into every adopting repo by default, which the core model excludes

1. Register the coordinator under the `review` role instead of adding one

- Pros
- `review` carries the exact tool set the coordinator declares, so no vocabulary change is needed and no new term has to be learned
- Three agents already use the role, so the registry stays smaller

- Cons
- The role's intent is to inspect work and report findings against repo standards, which is not what a workflow-transition coordinator does
- Dilutes a term three reviewers share and makes the role-to-function mapping misleading for a reader
- Records a function the agent does not perform, which is the same class of inaccuracy as the unregistered state it replaces, only moved from absence to misstatement

## Rollout Plan

Phase 0, record and approve

1. Publish this ADR as `Proposed`.
2. Obtain maintainer acceptance before treating it as binding, since the change edits two approval-protected core files.
3. Confirm the corrected registration rule from this ADR, which replaces the mis-scoped version in the originating review, is the rule that gets implemented.

Phase 1, role vocabulary and coordinator registration

1. Add the `advisory` role to `.github/roles/tool-access.json` with `read`, `search`, and `todo`.
2. Add `orchestration-coordinator` to `agentCapabilityMatrix` and `agentRoleHints`.
3. Align the coordinator's role string in `.github/agent-catalog.md` to the vocabulary.
4. Run the umbrella check on both platforms. The existing validators cannot fail on this slice, because no rule reads the coordinator yet.

Phase 2, adapter map and the atomic capability change

1. Add `hostAdapters` under `delegationDepth` in `.github/roles/orchestration-policy.json`, with the delegation tool names confirmed per host and `unsupported` recorded where none exists.
2. Extend `delegation-supervisor.agent.md` frontmatter with the host delegation tool and an `agents` allow-list within the canonical `specialistAllowList`.
3. Replace exact set equality with contains-plus-adapter-allow-list in both validator twins, and derive the delegation vocabulary from the map instead of the literal.
4. Add the pairing rules in the same change. This slice cannot be split without a red tree.

Phase 3, registration direction

1. Add the rule that every agent file not on the specialist allow-list must have a matrix entry and a role hint.
2. Keep the allow-listed tolerance and its positive fixture unchanged.

Phase 4, fixtures

1. Add negative fixtures per platform: a second declaration of the host tool; a non-supervisor declaring `agents`; the holder declaring `agents` without the host tool; the holder declaring the host tool without `agents`; an adapter-declared name that resolves to a mutating capability; a non-allow-listed agent file with no matrix entry.
2. Confirm the existing positive fixtures still pass unchanged.

Phase 5, documentation

1. Update `docs/runbooks/supervisor-orchestration.md` for the pairing rules and the adapter map.
2. Add the amendment pointer to ADR 0003.
3. Add `CHANGELOG.md` and `DOC-CHANGELOG.md` entries.

Phase 6, deferred

1. Decide whether task classes, playbooks, and evidence requirements belong in the policy file, as a separate ADR.
2. Reconsider the coordinator's future only if routing policy as data leaves it without a job, and only with usage evidence.

## Validation

These are the required validation activities for this decision. They are not themselves a record of completed work; executed status belongs in `CHANGELOG.md`.

Verify the decision works in practice by:

- Confirming all existing checks still pass, including the literal assertions in `check-approval-gated-orchestration.sh` and `check-agent-contracts.sh` and the pinned phrases in ADR 0003 and the supervisor runbook.
- Running `.github/scripts/check-supervisor-orchestration.sh` and `.github/scripts/check-supervisor-orchestration.ps1`, both registered in the paired workflow entry points.
- Confirming the validator fails when a second agent declares the host delegation tool; when a non-supervisor declares an `agents` allow-list; when the holder declares `agents` without the host tool; when the holder declares the host tool without `agents`; when `agents` names an agent outside the canonical `specialistAllowList`; when an adapter-declared name resolves to `edit` or `execute`; when an `agentCapabilityMatrix` entry enables a host adapter tool name; when a non-allow-listed agent file has no `agentCapabilityMatrix` entry; and when a matrix entry or role hint diverges from the frontmatter. Each case is a negative fixture, so the branches cannot regress into silent no-ops.
- Confirming the positive fixtures still pass: the shipped tree is accepted, an allow-listed non-mutating agent with no matrix entry is still tolerated — the reason the registration rule is scoped to non-allow-listed agents — an unsupported host recorded with an empty `delegationTools` list is accepted on both platforms, and a case-variant adapter tool name is treated as a distinct non-mutating host name on both platforms.
- Confirming that no core behavior changes when the overlay is disabled: guided handoffs, the one-main-chat model, and the core handoff contract fields stay identical.
- Confirming that no edited or new document describes the approval gate as enforced authorization, so the enforcement-framing guard over `.github/agent-catalog.md`, `.github/roles/tool-access.json`, and every agent file still passes.
- Confirming `check-markdown-quality.sh` passes, since new and edited documentation is scanned for trailing whitespace and broken local links.

## Follow-up

- Review trigger: the first repo that enables the overlay with a delegation that crosses a high-risk category gate, or the first host added to the adapter map.
- Revisit if hosts diverge on delegation semantics rather than on tool naming. The adapter map covers naming; semantic divergence is the signal that per-host agent files were the right answer after all.
- Revisit if the adapter map is found to admit a name that resolves to a mutating capability, which would mean the closed-set check is not closed.
- Revisit the coordinator's mandate if routing policy as data leaves it with no distinct responsibility.
- Host delegation tool names were confirmed against host documentation before Phase 2 landed: `agent` and `runSubagent` for VS Code / GitHub Copilot on 2026-09-14, and `agent` (documented aliases `custom-agent` and `Task`) for the GitHub Copilot CLI and cloud.
- This ADR is `Accepted` as of 2026-09-14. Adopting repos are bound by it once they enable the overlay.
- Implementation status as of 2026-09-14: Phases 1, 2, 3, and 5 of the Rollout Plan have landed, together with all six Phase 4 fixtures per platform plus three additional negative fixtures per platform (`supervisor-frontmatter-extra-tool`, pinning the closed side of the adapter allow-list, `non-allow-listed-agent-without-role-hint`, pinning the role-hint half of the registration rule, and `adapter-enabled-in-capability-matrix`, pinning the matrix adapter-tool guard). `delegationDepth.hostAdapters` exists in `.github/roles/orchestration-policy.json` with the delegation tool names verified against host documentation on 2026-09-14: `agent` and `runSubagent` for VS Code / GitHub Copilot, and `agent` for the GitHub Copilot CLI and cloud (documented aliases `custom-agent` and `Task`). Both validator twins derive the platform delegation vocabulary from the map, enforce the contains-plus-closed-adapter-allow-list rule, the two pairing rules, the mutating-name guard, and the reverse registration direction, and run twenty-nine negative fixtures plus three positive fixtures per platform. The second positive fixture pins the empty-`delegationTools` representation for unsupported hosts, and the third pins the case-sensitive mutating-name guard. The unregistered-coordinator defect and the inert-delegation defect are both closed for the shipped tree.
- Phase 6 is deferred by design. The `agentCapabilityMatrix must not enable host adapter tools` rule, previously the one unpinned branch from the Phase 2 slice, is now fixture-pinned, as is the case-sensitive mutating-name guard.
