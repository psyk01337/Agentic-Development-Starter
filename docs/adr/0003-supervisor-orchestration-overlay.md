# ADR 0003: Supervisor Orchestration Overlay

- Status: Accepted
- Date: 2026-09-11
- Approved: 2026-09-12 by the repository maintainer (user), recorded as the required approval for a `core-governance-change`
- Owners: Team
- Related: `docs/adr/0001-approval-gated-orchestration-overlay.md`, `.github/AGENTS.md`, `.github/starter-modules.json`, `.github/roles/tool-access.json`, `.github/hooks/agent-policy.json`, `docs/runbooks/approval-gated-handoffs.md`, `docs/runbooks/agentic-dev.md`

## Context

The core starter runs on one main chat as orchestrator plus guided handoffs. Hidden automatic multi-agent chains are deliberately excluded from core behavior (`AGENTS.md`, Deliberate Exclusions). ADR 0001 added approval-gated *human* transitions through the `orchestration-coordinator`, but it explicitly does not cover *machine* task delegation, and it states that approval metadata is workflow metadata rather than enforced authorization.

Teams have since asked for a supervisor that can delegate bounded tasks to approved specialist agents. The stated requirement is that safety must not depend on installing another optional module.

An independent architecture review on 2026-09-11 established four facts that shape this decision.

1. No core file encodes a general high-risk approval gate. The only core rules of that character are scope-based (`copilot-instructions.md:15`, "Ask before doing broad refactors") or narrow (`security.instructions.md:41`, auto-update review; one hook rule for explicitly unapproved core-policy edits in `.github/hooks/policy-rules.tsv`). High-risk approval semantics are overlay-only today.
2. The module manifest has no dependency mechanism. Modules carry `id`, `kind`, `defaultEnabled`, `when`, and `files` only, and `check-starter-manifest.sh` validates exactly those fields. A declared dependency would be inert documentation, not an enforced install requirement.
3. Implementation is not file-level additive. `.github/AGENTS.md` belongs to `core-agents` and `.github/roles/tool-access.json` belongs to `core-governance`, so an overlay that adds an agent and a role must edit two core modules even though it changes no core behavior when disabled.
4. The repository already sanctions this class of change. `starter-composition.md:188` states that agent-to-agent orchestration should be added as an optional overlay with explicit approval and audit behavior, and `AGENTS.md:209` reserves the same path. Only the exclusion phrase "Automatic multi-agent handoff chains" (`AGENTS.md:206`) is ambiguous and needs narrowing.

The real decision is therefore not whether to declare a dependency, but where the irreducible high-risk approval gate lives.

## Decision

Add a default-disabled overlay module `overlay-supervisor-orchestration` (`kind: "overlay"`, `defaultEnabled: false`) that adds the `delegation-supervisor` agent, able to delegate bounded tasks to approved specialist agents. The agent file is `.github/agents/delegation-supervisor.agent.md`.

`delegation-supervisor` is deliberately distinct from `orchestration-coordinator`. The coordinator governs human-guided workflow transitions and approval-gated handoffs; the supervisor governs machine delegation of bounded tasks. The two agents are not merged and must not be.

Specifically:

- The supervisor carries the new abstract capability `delegate-agent` and the new role `orchestration` = `[read, search, todo, delegate-agent]`. It has no `edit` and no `execute`, so it cannot mutate state directly.
- Only the supervisor holds `delegate-agent`. Workers cannot delegate. Nested and recursive delegation stay disabled in v1.
- The overlay carries its own irreducible high-risk approval gate, and does **not** depend on `overlay-approval-gated-orchestration`. Where both overlays are present, the supervisor reuses the approval overlay's transition envelope fields; where only this overlay is present, it enforces its own gate. There is exactly one gate definition per composition.
- Every write-class delegation declares its intended write set in the delegation artifact. Parallel write delegations are permitted only on declared-disjoint sets. When the write set cannot be established, write delegations are serialized rather than run in parallel.
- The complex branch requires a consolidated plan artifact before implementation delegation. The simple branch may delegate directly. The routing criterion is fixed in `.github/roles/orchestration-policy.json`: a task is complex if it matches any of the eleven stated conditions, is complex when uncertain, and must not be classified by file count, prompt size, or token count.
- `.github/roles/orchestration-policy.json` is the single canonical machine-readable source for the approval-required categories, the specialist allow-list, the delegation depth, the routing criteria, and the write-set rule. Other documents explain those rules but must not carry a second authoritative copy.
- The approval-required categories are `architecture-change`, `core-governance-change`, `dependency-change`, `destructive-data-change`, `identity-security-change`, `production-or-deployment-change`, `destructive-operation`, and `scope-expansion`.
- The specialist allow-list is fixed to `analyst`, `tech-planner`, `architecture-reviewer`, `senior-software-engineer`, `code-reviewer`, `security-reviewer`, `qa`, `tdd-vitest`, and `documentation-maintainer`. Arbitrary agent invocation is not permitted.
- If native subagents are unavailable, the supervisor emits an ordered delegation plan for the user to execute, or refuses the delegation. It never degrades silently.
- ADR 0001 remains `Accepted` and is not modified. This ADR complements it. Only the ambiguous exclusion at `AGENTS.md:206` is narrowed to distinguish human-gated approval transitions and machine task delegation.

The gate introduced by this ADR is a prompt-level contract, not enforcement. This repository has no trusted identity source or validated enforcement point for approval, and no hook seam for agent-to-agent delegation. Documentation must not describe the gate as enforced authorization.

Option C, promoting a minimum high-risk approval rule into core (`security.instructions.md` or `core.instructions.md`), is deferred to a separate proposal with its own ADR. It must not be bundled into this overlay.

## Consequences

Positive outcomes

- Teams gain a sanctioned pattern for machine task delegation without changing core behavior or enabling anything by default.
- The supervisor declares no `edit` and no `execute` capability, so its authority is limited to delegation by declaration rather than by promise. That declaration is a repo-level prompt contract over an abstract capability name, and the platform mapping of `delegate-agent` stays unverified until it is tested in a target environment.
- The single-holder and no-nesting rules keep the privilege surface small and auditable.
- Adoption independence is preserved: the overlay is safe to install without a second optional module.

Trade-offs and risks

- The gate is a convention, not a control. Nothing prevents an operator from ignoring it, and no validator can detect a bypassed approval.
- The overlay edits two core modules (`AGENTS.md` in `core-agents`, `tool-access.json` in `core-governance`), so it is additive in behavior but not at the file level.
- Adding the `orchestration` role to the always-present `tool-access.json` leaves an idle role in repos that never enable the overlay.
- The write-set rule is not machine-enforced in v1, so overlapping parallel writes depend on review discipline.
- `delegation-supervisor` and `orchestration-coordinator` both concern orchestration, so the runbook, the agent catalog, and the ownership map must state the distinction explicitly or readers will conflate them.
- Delegation makes the supervisor a privilege broker for agents that do hold `edit` and `execute`, so the delegation boundary, not the supervisor role itself, is the security-relevant surface.

Operational impacts

- Adopting repos must add the overlay to their manifest and register the supervisor in `tool-access.json` in three places, per `starter-composition.md:186`.
- Validators must be registered in both workflow entry points or they will never run, because `check-starter-workflow.sh` and `.ps1` hardcode their script list.
- Enabling the overlay requires a security review of the delegation boundary. That review carries two mandatory preconditions rather than recommendations:
  - Confirm that tool invocations made by a delegated subagent remain subject to the repository's `preToolUse` hook policy in the target runtime, and record the evidence. `preToolUse` is the only mechanical guardrail in this starter (`docs/runbooks/hooks.md:58-61`), the allow-list includes workers that hold both `edit` and `execute`, and hooks cannot protect runtimes that do not invoke the hook lifecycle. If the runtime cannot provide this evidence, record the gap explicitly rather than enabling the overlay on an assumed control. An absent result scopes enablement rather than blocking it; see the capability-scoped rule below.
  - Confirm how `delegate-agent` maps to the host runtime's delegation primitive, per the Supported Runtimes table in `docs/runbooks/supervisor-orchestration.md`, and record whether the host provides one at all. This is the mapping the Consequences section calls unverified until tested.

The hook-inheritance precondition is capability-scoped rather than overlay-wide, because the exposure it guards is created by the delegated worker's capability rather than by the overlay being enabled. `delegation-supervisor` declares no `edit` and no `execute`, so the supervisor's own surface is identical whether the precondition is satisfied or not. The risk this precondition addresses is a worker that holds `edit` or `execute` acting while the only mechanical guardrail is absent.

| Hook-inheritance evidence | Permitted delegation |
| --- | --- |
| Verified in the target runtime | The full `specialistAllowList`. |
| Unverified or unverifiable | The non-mutating tier only: agents whose declared capabilities are a subset of `read`, `search`, and `todo`. In the shipped allow-list that is `architecture-reviewer`, `code-reviewer`, and `security-reviewer`. Mutating delegation stays blocked until the evidence exists. |

A team that cannot obtain the evidence and needs mutating delegation may enable it only as a recorded, maintainer-approved exception: the gap recorded, every write delegation serialized, and every delegation plan reviewed by a human before execution. That is accepted residual risk with a named approver, not a default path.

The non-mutating tier is derived from each agent's `tools` frontmatter, which the overlay validators already cross-check against `agentCapabilityMatrix` in `.github/roles/tool-access.json`. The frontmatter scan is the authoritative side, so an agent whose matrix entry is absent cannot shrink the tier. Both paired validators assert two properties of that definition rather than of runtime behavior. The first is that the derived tier is non-empty, so a later edit cannot silently reduce the capability-scoped rule to the total block this ADR rejects. The second is the tolerance the derivation relies on: a positive fixture removes one allow-listed non-mutating member's `agentCapabilityMatrix` entry and requires the validator to accept the result, so that documented state cannot start being rejected without a check going red. It is a static definition plus an operating obligation, not a machine-enforced restriction, and it must not be described as one. Enforcement is deliberately not recorded as a machine-readable status field in `orchestration-policy.json`: a self-attested `verified` flag would be an unverifiable claim that a later reader could mistake for a checked fact, which is the failure mode this ADR exists to prevent. The evidence belongs in the adopting repo's delegation-boundary review record.

Neither precondition is observable by a static check, so neither can be enforced by the overlay validators. They gate enablement, not the merge of the default-disabled assets, and the first one gates the delegable capability surface rather than enablement itself. The validators therefore assert nothing about the preconditions themselves. What they check about the fallback is static and limited: the tier is defined and non-empty, and the tolerated state above stays accepted.

## Options Considered

1. Option A: hard dependency on `overlay-approval-gated-orchestration`

- Pros
- Reuses an existing approval definition
- Makes the composition explicit in the manifest

- Cons
- No dependency mechanism exists, so it would be inert documentation
- Forces one default-disabled overlay to drag in another, weakening composability
- Does not satisfy the requirement, because safety would still hinge on an optional module

1. Option B: self-contained gate inside the supervisor overlay

- Pros
- Satisfies the installation-independence requirement
- Keeps blast radius inside one default-disabled overlay
- Changes no core behavior when disabled

- Cons
- The gate still lives in an overlay, so the "core safety root" is not actually achieved
- Duplicates semantics that ADR 0001 already expresses, unless composition is stated explicitly

1. Option C: promote a minimum high-risk gate into core

- Pros
- Actually realizes the intended model, where both guided and supervisor workflows inherit the gate
- Makes safety genuinely module-independent and benefits every workflow

- Cons
- Changes core files shipped to every adopting repo
- Requires its own consensus process and would breach the "no core behavior change" constraint if bundled here

1. Write-set handling: prose convention only

- Pros
- No new artifact to define or validate

- Cons
- Unreviewable, because the intended file set is never written down
- Gives no basis for later automation

1. Write-set handling: declared write set plus serialize-when-unknown

- Pros
- Makes parallel writes reviewable and gives a deterministic default
- Preserves the parallel-delegation benefit where the sets are provably disjoint
- Leaves a clean upgrade path if a validator is added later

- Cons
- Adds an artifact field that nothing enforces in v1
- Depends on delegators declaring the set honestly

1. Nesting enabled in v1

- Pros
- Supports deeper task decomposition in one pass

- Cons
- Reasoning cost, permission reasoning, and loop risk all grow combinatorially
- Widens the privilege surface beyond a single delegation layer

## Rollout Plan

Phase 0, record and approve

1. Publish this ADR as `Proposed`.
2. Obtain maintainer acceptance before treating it as binding, since the change edits two core modules.
3. Confirm the deferred Option C proposal is tracked separately rather than dropped silently.

Phase 1, shared contracts

1. Add `delegate-agent` to `toolDefinitions` in `.github/roles/tool-access.json`.
2. Add the `orchestration` role scoped as overlay-intent.
3. Create `.github/roles/orchestration-policy.json` as the canonical machine-readable source for the approval categories, routing criteria, delegation depth, specialist allow-list, and write-set rule, and reference it from both overlays so composition is testable rather than prose-only.

Phase 2, registration across existing assets

1. Add the overlay entry to `.github/starter-modules.json` and bump the manifest minor version.
2. Add the supervisor to `agentCapabilityMatrix` and `agentRoleHints` in `.github/roles/tool-access.json`.
3. Update `.github/AGENTS.md`: agent set, ownership map, sequencing shortcuts, and the narrowed `:206` exclusion. Leave `:209` unchanged.
4. Align `rolePolicyGuidance` in `.github/hooks/agent-policy.json`.
5. Add the agent to `docs/runbooks/agentic-dev.md` chain and handoff-memory lists.
6. Register the new runbook in `docs/runbooks/INDEX.md` in both lists.
7. Add migration guidance to `MIGRATION.md` and the overlay to `docs/runbooks/starter-composition.md`.

Phase 3, overlay artifacts

1. Add the `delegation-supervisor` agent with `## Handoff Memory Contract` and `## Escalation and Failure Modes`.
2. Add the orchestration skill, runbook, and delegation-plan schema.
3. Add a delegation-plan example under `.github/examples/supervisor-orchestration/`.
4. State the `orchestration-coordinator` versus supervisor distinction in the runbook's first paragraph.

Phase 4, validators

1. Add `check-supervisor-orchestration.sh` and `.ps1`.
2. Register both in `check-starter-workflow.sh` and `.ps1`. Without this they never run.
3. Extend the agent lists in `check-agent-contracts.sh` and `.ps1`, or replace the fixed list with a manifest-driven scan.

Phase 5, docs and changelogs

1. Add the overlay to the README overlay summary.
2. Add `CHANGELOG.md` and `DOC-CHANGELOG.md` entries.

Phase 6, deferred

1. Raise Option C as a separate proposal and ADR.
2. Consider a manifest dependency mechanism only as its own schema change with its own validator.

## Validation

These are the required validation activities for this decision. They are not themselves a record of completed work; executed status is recorded in `CHANGELOG.md`.

Verify the decision works in practice by:

- Confirming all existing checks still pass, including the literal assertions in `check-approval-gated-orchestration.sh` and `check-agent-contracts.sh`.
- Running `.github/scripts/check-supervisor-orchestration.sh` and `.github/scripts/check-supervisor-orchestration.ps1`, both registered in the paired workflow entry points.
- Confirming the new validator fails when a non-supervisor agent declares `delegate-agent` — in its own frontmatter, in a capability-matrix entry, or in an agent file that carries no matrix entry — when any agent's frontmatter diverges from its `agentCapabilityMatrix` entry, when the supervisor frontmatter tools diverge from the `orchestration` role, when the specialist allow-list admits a delegation-capable agent, when the non-mutating tier empties because every allow-listed agent gained a mutating capability, and when the manifest `defaultEnabled` is not `false`. The validators exercise these cases as negative fixtures, so the branches cannot regress into silent no-ops, and they validate the delegation-plan example against `delegation-plan.schema.json`.
- Confirming that no core behavior changes when the overlay is disabled: guided handoffs, the one-main-chat model, and the core handoff contract fields stay identical.
- Confirming the disabled-overlay runbook does not imply the gate is enforced authorization.
- Confirming, in the target runtime and as an enablement precondition, that a delegated subagent's tool calls are still subject to `preToolUse`, and recording the result. No static validator can observe this, which is why it is stated as an enablement obligation in the runbook instead. An unverified result does not block enablement; it restricts delegation to the non-mutating tier described under Operational impacts.
- Confirming `check-markdown-quality.sh` passes, since new documentation is scanned for trailing whitespace and broken local links.

## Follow-up

- Review trigger: the first repo that enables the overlay, or the first time a delegation crosses a high-risk category gate.
- Revisit if two or more adopting repos report that prompt-level gating is insufficient, which is the signal that Option C is due.
- Revisit if the supervisor needs nesting, a second delegation layer, or a wider tool surface.
- Revisit if the write-set rule is bypassed in practice or becomes costly to review.
- This ADR is `Accepted` as of 2026-09-12; adopting repos are bound by it once they enable the overlay.
- Implementation status: the overlay assets described here are present in the repository as of 2026-09-11. The paired overlay validators, both workflow entry points, and the Markdown quality check were executed on 2026-09-12 and pass, alongside the independent code review, security review, and QA pass; results are recorded in `CHANGELOG.md`. The maintainer accepted this ADR on 2026-09-12, which supplies the recorded approval the `core-governance-change` classification requires because the change adds entries to two core modules (`AGENTS.md` in `core-agents`, `tool-access.json` in `core-governance`).
