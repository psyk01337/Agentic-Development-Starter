# ADR 0005: Routing Policy as Data — Task Classes, Playbooks, and Evidence Requirements in the Policy File

- Status: Accepted
- Date: 2026-09-14
- Approved: 2026-09-23 by the repository maintainer (user), after the architecture review passed with conditions F1-F4, which the 2026-09-14 amendment resolved in this ADR's own text
- Owners: Team
- Related: `docs/adr/0004-adapter-bound-delegation.md` (Phase 6), `docs/adr/0003-supervisor-orchestration-overlay.md`, `.github/roles/orchestration-policy.json`, `.github/scripts/check-supervisor-orchestration.sh`, `.github/scripts/check-supervisor-orchestration.ps1`, `.github/agents/delegation-supervisor.agent.md`, `.github/skills/supervisor-orchestration/SKILL.md`, `docs/runbooks/supervisor-orchestration.md`

## Context

ADR 0004's Decision states the principle and defers the work: "Routing policy stays data. Task classes, playbooks, and evidence requirements belong in `.github/roles/orchestration-policy.json`, not in prose inside an agent file, because a table can be pinned by negative fixtures and prose cannot. This ADR does not add those keys; it fixes the capability model they would depend on." Phase 6 of ADR 0004 names the decision this ADR makes.

Today the policy file carries `complexityRouting` as data — the eleven simple-versus-complex criteria, the two workflow strings, and the fallback mode — but the rest of the routing model is prose. The vNext direction names thirteen task classes (QUESTION through UNKNOWN_COMPLEX), maps each to an ordered playbook, requires an explicit reason for every skipped stage, and defines verification evidence per change surface (UI, API, database, CLI, configuration, library) with a VERIFIED / NOT_VERIFIED / INCONCLUSIVE vocabulary. The completion invariant is: no agent may mark work complete; only the orchestrator declares completion, and only when the defined success predicate has direct verification evidence.

None of that is currently machine-readable. A task class can be renamed, a playbook stage dropped, or an evidence requirement forgotten, and no check goes red, because no check reads prose.

## Decision

Add three additive, overlay-scoped keys to `.github/roles/orchestration-policy.json` and make them the single source of truth for the supervisor's routing surface:

- `taskClasses`: the thirteen-class taxonomy as an ordered list of objects (`id`, `description`). The ids are a closed vocabulary: QUESTION, INVESTIGATION, BUG_FIX, FEATURE, REFACTOR, ARCHITECTURE, SECURITY, PERFORMANCE, TESTING, DOCUMENTATION, MIGRATION, INFRASTRUCTURE, UNKNOWN_COMPLEX.
- `playbooks`: a map from task-class id to an ordered stage list. Each stage is an object with `id`, `name`, `delegatesTo`, and `skipRequiresReason: true` for every stage — the playbook is guidance, not an excuse to skip, and every skipped stage must carry an explicit recorded reason. `delegatesTo` values are case-sensitive and must be allow-listed agent ids or the literal `delegation-supervisor` for orchestrator-owned stages. A stage requiring human approval sets `requiresHumanApproval: true` with an empty `delegatesTo`; exactly one of a non-empty `delegatesTo` and `requiresHumanApproval: true` is set per stage.
- `evidenceRequirements`: the fixed result vocabulary `["VERIFIED", "NOT_VERIFIED", "INCONCLUSIVE"]`, the completion rule in data form (`completionRule: orchestrator-declared-after-verification-evidence`), `inconclusiveNeverSuccess: true`, and a `surfaces` map over the closed surface vocabulary — `ui`, `api`, `database`, `cli`, `configuration`, `library` — each holding its required evidence kinds.

Classification has two complementary axes, and both live in the policy file. `taskClasses` owns playbook selection: the classifier names a task class, and the class's playbook supplies the ordered stages. `complexityRouting` owns escalation: the existing eleven criteria yield a `simple` or `complex` verdict, and that verdict selects the workflow envelope (`simpleWorkflow` or `complexWorkflow`) the playbook executes inside. Neither axis duplicates the other; the supervisor records both the task class and the complexity verdict with its routing criterion.

The paired validator twins gain deterministic checks over these keys and negative fixtures per platform. The supervisor agent file and runbook stop duplicating the routing prose and point at the policy keys instead. The completion invariant remains a prompt-level contract: this ADR adds no enforcement point and no documentation may describe completion as machine-enforced, consistent with `enforcement.runtimeEnforced: false`.

The change is overlay-scoped: `orchestration-policy.json` declares `appliesTo: overlay-supervisor-orchestration`, and no core module is edited.

## Consequences

Positive outcomes

- Routing becomes checkable. A dropped class, an empty playbook, a stage that names an agent outside the allow-list, or an unknown class id in a playbook goes red on both platforms instead of drifting in prose.
- The supervisor's routing behavior has one canonical source, the same single-source pattern ADR 0004 established for delegation depth and host adapters.
- Playbook stages name agents by id, which the validators can resolve against the allow-list and the capability matrix, so routing references cannot rot silently.

Trade-offs and risks

- The taxonomy and playbooks become fixed by fixtures. Changing a class id or stage order becomes a governance change with changelog and fixture updates, which is the intended cost of auditability.
- The schema grows. Three new keys with nested objects make the policy file larger, and the validator twins each gain one more scanning block; the risk is mitigated by keeping the checks shape-based rather than enumerating every stage name.
- `delegatesTo` is advisory, not enforced: the validator checks the names resolve to the allow-list, but nothing at runtime prevents a human from routing differently. This matches the overlay's prompt-contract posture.
- UNKNOWN_COMPLEX remains a deliberate catch-all whose playbook is investigation → design → execute → verify → review, and its presence in data makes the fallback explicit instead of implicit.

Operational impacts

- The policy file moves from version 1.0 to 1.1 in the slice that adds the keys.
- The supervisor agent file and runbook are edited in the same slice so no document describes routing that the data does not carry.
- Both validator twins change together, with negative fixtures per platform, and both stay registered in the paired workflow entry points.
- No core file changes, so this ADR carries no `core-governance-change` gate. It passed architecture review on 2026-09-14 with conditions F1-F4, resolved in the Decision text, and the maintainer accepted it on 2026-09-23; rollout slices 2 through 4 land after acceptance.

## Options Considered

1. Status quo: routing stays prose

- Pros: no schema growth, no fixture cost, fastest to leave alone.
- Cons: the drift class ADR 0004 predicted is already visible — the runbook, agent file, and policy file each describe routing in their own words, and no check catches divergence.

1. Playbooks in a new file instead of the policy file

- Pros: keeps `orchestration-policy.json` small.
- Cons: splits the canonical routing source across two files when the policy file already exists as the overlay's single source of truth, and ADR 0004's Decision explicitly named this file as the destination.

1. Full machine enforcement of routing and completion

- Pros: deterministic transitions and completion gates.
- Cons: ADR 0001 refuses a core runtime orchestration engine; there is no trusted identity source or enforcement point for agent-to-agent delegation; and `enforcement.runtimeEnforced: false` forbids claiming it. Rejected.

1. Taxonomy and playbooks in the policy file, evidence vocabulary fixed in data — adopted here

- Pros: routing becomes fixture-pinnable without pretending the prompt-level contract is enforcement; matches ADR 0004's stated direction and the vNext playbook guidance.
- Cons: schema growth and the governance cost of changing pinned data, accepted as the price of auditability.

## Rollout Plan

1. Record and approve: publish this ADR as `Proposed`, obtain architecture review and maintainer acceptance before implementation. Done: the architecture review passed with conditions F1-F4 on 2026-09-14, the amendment of the same day resolved them, and the maintainer accepted the ADR on 2026-09-23.
2. Data first: add `taskClasses`, `playbooks`, and `evidenceRequirements` to `orchestration-policy.json` (version 1.0 → 1.1). Nothing reads them yet, so this slice cannot go red on its own.
3. Validators: add the taxonomy/playbook/evidence checks to both twins with negative fixtures per platform — at minimum: a removed task class, an empty playbook, a stage naming an agent outside the allow-list, a stage with both a non-empty `delegatesTo` and `requiresHumanApproval: true`, a playbook referencing an unknown class id, a mutated evidence vocabulary, an unknown surface id, and a completion rule edit. The same slice pins the existing `complexityRouting` data, which no validator currently reads: `defaultWhenUncertain` fixed to `complex`, non-empty `simpleWorkflow` and `complexWorkflow` strings, and non-empty `complexIfAny` and `notBasedOn` lists. Run both overlay validators and both umbrellas.
4. Docs: update the runbook's routing section and the supervisor agent file to reference the policy keys, and remove the duplicated prose. Update both changelogs.

## Validation

- Both validator twins reject a policy file that drops a task class, carries an empty playbook, names an agent outside the allow-list in a stage, references an unknown class id, mutates the evidence vocabulary, or changes the completion rule — each as a negative fixture with a unique message substring.
- The shipped policy file passes both twins.
- `bash .github/scripts/check-starter-workflow.sh` and `pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1` pass all ten checks on both platforms.
- No document describes routing or completion as machine-enforced; the enforcement-framing guard over governance text still passes.

## Follow-up

- Review trigger: the first time a task class or playbook stage is changed for a real project, to judge whether the fixture discipline is helping or merely taxing.
- Revisit if the taxonomy proves too coarse or too fine for actual routing decisions.
- Revisit the `delegatesTo` advisory status if a host ever provides a machine-readable routing hook.
