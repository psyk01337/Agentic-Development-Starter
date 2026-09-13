# Documentation Changelog

Use this log for changes to documentation assets such as Markdown, text files, ADRs, runbooks, onboarding notes, release notes, and other non-executable reference material.

## How To Use

1. Add a new entry whenever Markdown, text, or other documentation files change in a way that affects understanding, setup, operations, contracts, or review context.
2. Cross-reference the related implementation entry in `CHANGELOG.md` when the docs describe or explain a code change.
3. If the documentation-only change has no matching code change, say so explicitly.
4. Record discrepancies when docs intentionally lag code or when a follow-up doc update is still required.

## Entry Template

### YYYY-MM-DD - Short change title

- Area: guide, runbook, ADR, README section, or repo path
- Change type: docs, adr, runbook, onboarding, release-notes, policy, reference
- Summary: what changed in the documentation set
- Reason: why the doc update was needed
- Affected files: relevant paths
- Related code: matching `CHANGELOG.md` entry, code path, or `None`
- Review status: reviewed, pending-review, or not-applicable
- Discrepancies or follow-up: known gaps, deferred updates, or `None`

## Entries

### 2026-09-12 - Add a usage guide to the README

- Area: README (repo landing guide)
- Change type: docs, onboarding
- Summary: added a `Start Here` reading order and a `How To Use This Repo Well` section to `README.md`, both linked from the table of contents. The new section records the per-task loop (frame, route, deliver, verify, record, validate, hand off), a table for choosing between instructions, prompts, skills, agents, ADRs, runbooks, and hook rules, adoption-mode selection by team shape, the repo-truth and validation expectations, a seven-step checklist for extending the starter with a new agent, skill, or prompt, and a short list of common mistakes. The `Validation Commands` section now names the `Makefile` targets and the two CI workflows that run the same contracts. Existing Quick Start, Adoption Modes, catalog, and Roadmap content is unchanged.
- Reason: the README catalogued what the starter contains but not how to operate it. Prompt, skill, and agent inventories, adoption-mode lists, and validation scripts were all present without guidance on which surface to reach for, in what order to use the roles, or what to do when adding a new asset, so an adopter had to reconstruct the daily workflow from `docs/runbooks/agentic-dev.md` and `.github/AGENTS.md`.
- Affected files: README.md, DOC-CHANGELOG.md
- Related code: None; no executable asset changed.
- Review status: pending-review
- Discrepancies or follow-up: README content beyond Markdown link integrity and trailing whitespace is not pinned by any validator, so the new surface table, the extension checklist, and the `Makefile` target enumeration can drift from `.github/starter-modules.json`, `.github/AGENTS.md`, `.github/roles/tool-access.json`, and the runbooks without a failing check. Adding an assertion for the README's surface-to-directory mapping was left out of this slice deliberately. `QUICKSTART.md` still duplicates the README quick-start steps and was not touched, so the two can drift independently. The earlier entries in this log remain `pending-review`.

### 2026-09-12 - Correct the "Unable to resolve action" troubleshooting guidance

- Area: TROUBLESHOOTING.md validation section
- Change type: docs
- Summary: replaced the "VS Code local resolver limitation ... safely ignore" explanation with the verified mechanism and ordered remediation steps. The section now states that the GitHub Actions extension's language server resolves each `uses:` entry by fetching that action's `action.yml` through the GitHub API, that every failed fetch collapses into the same "repository or version not found" message, and that the ref form is not a factor. It adds two commands that prove the refs resolve, plus sign-in, connectivity, cache-reload, and log-inspection steps. It also maps the extension log's HTTP status to the underlying cause, because the generic message hides it: `401 Bad credentials` for an expired, revoked, or wrong-account token, `403` for an exhausted rate limit, and `404` for a ref that genuinely does not exist.
- Reason: the previous text asserted a cause without evidence and offered no action, and the same unresolved warning was carried forward as a known diagnostic in two 2026-06-06 `CHANGELOG.md` entries. Reading the bundled language server showed the resolver calls `repos.getContent` and maps every failure to that one message, and live probes of that exact endpoint returned `200` for `@v3`, `@v4`, `@v4.4.0`, and the commit SHA, so the warning is not caused by the workflow refs.
- Affected files: TROUBLESHOOTING.md, DOC-CHANGELOG.md
- Related code: None; no executable asset changed.
- Review status: reviewed
- Discrepancies or follow-up: no workflow file changed, because the workflow refs are valid as written. A separate finding is unresolved: `.github/workflows/validation.yml` and `.github/workflows/skill-contract-tests.yml` reference `actions/checkout` by mutable major tags (`@v4` and `@v3`) instead of the full commit SHA required by `.github/instructions/ci.instructions.md`. That is a supply-chain policy gap, not the cause of this warning, and it needs a maintainer decision.

### 2026-09-12 - Record the SEC-1 skip notice, the corrected index wording, and ADR 0003 acceptance

- Area: overlay runbook, overlay ADR
- Change type: docs, adr, runbook, policy
- Summary: the runbook's fixture paragraph and the matching entry below now scope the "non-zero index" rationale the way the code comment already did: the entry-absent state is observed at the last member's index, which is non-zero for any tier larger than one and index 0 for a single-member tier, while the dropped-removal self-check still fires at every legal tier size. ADR 0003 is now `Accepted`, carries a `- Approved:` line recording the 2026-09-12 maintainer approval for the `core-governance-change`, and its implementation-status line records the 2026-09-12 validation and review state instead of the 2026-09-11 execution.
- Reason: independent code review found the "at every legal tier size including a single-member tier" clause over-generalised, because a single-member tier reaches the entry-absent state at index 0; QA classified it as the non-blocking NB-1 item. The ADR's implementation-status line was stale after the 2026-09-12 validator edits, and the maintainer recorded approval for the `core-governance-change`, which is the moment to move the ADR out of `Proposed`.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-09-12 - Announce skipped fixtures, correct the index wording, and accept ADR 0003"
- Review status: reviewed
- Discrepancies or follow-up: the corrected sentences remain pinned by the paired text assertions on `requires the validator to accept the result` and `derived tier is non-empty`, and neither phrase was touched, so no assertion changed. The runbook's fixture enumeration is still a documentation-only list that no validator reads, so its count and case list can drift again. NB-2, NB-3, SEC-2, SEC-3, and SEC-4 remain open and are recorded in the matching `CHANGELOG.md` entry. The earlier entries in this log remain `pending-review`; this entry records the closeout and does not clear that status.

### 2026-09-12 - Record the tolerated-state fixture and scope the tier fixture's claimed coverage

- Area: overlay runbook, overlay ADR
- Change type: docs, adr, runbook
- Summary: the runbook's fixture paragraph now describes the suite as seventeen negative fixtures plus one positive fixture instead of negative fixtures alone, states that the tier mutation removes the last derived member's `agentCapabilityMatrix` entry before the mutation loop starts so that the loop observes the entry-absent state at the last member's index — a non-zero index for any tier larger than one and index 0 for a single-member tier — and a dropped removal is reported rather than passing, and stops claiming that the tier fixture exercises "both the frontmatter-authoritative path and the entry-absent path"; only the entry-absent half was pinned by an assertion, and the first-member deletion it described was unpinnable. It also records the new `allow-listed-agent-without-matrix-entry` positive fixture. The runbook's derivation paragraph and the matching ADR paragraph now state that both validators assert two properties of the tier definition rather than one: the tier is non-empty, and an allow-listed agent file with no `agentCapabilityMatrix` entry is accepted. Each document names the positive fixture as the thing that pins that tolerance.
- Reason: code review of the entry above returned `needs-revision`. The runbook and `CHANGELOG.md` described a fixture that exercised two paths when only one was asserted, and the tolerated state the tier fixture depends on was documented in both design documents but asserted by nothing, so a later edit that rejected it would have broken a documented contract with the suite still green. Recording the new fixture without recording it in the design documents would have left both documents claiming "one property" when the validators now assert two.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md
- Related code: CHANGELOG.md entry "2026-09-12 - Make the tier fixture's guarantee unconditional and pin the tolerated entry-absent state"
- Review status: pending-review
- Discrepancies or follow-up: both new sentences are pinned by paired text assertions on the phrase `requires the validator to accept the result`, mirroring how the neighbouring `derived tier is non-empty` claim is pinned, so that drift class cannot recur silently here. The fixture paragraph remains a documentation enumeration that no validator reads, so the eighteen-fixture count and the case list can drift again; pinning them was left out of this slice deliberately. ADR 0003's implementation-status line still records execution on 2026-09-11 and does not reflect the 09-12 validator edits. ADR 0003 remains `Proposed` pending maintainer acceptance, so no repo is bound by it yet. The earlier entries in this log remain `pending-review` and still need independent re-review.

### 2026-09-12 - Record the third validator in the architecture validation list

- Area: architecture reference, overlay runbook
- Change type: docs
- Summary: the validation workflow sequence diagram in `docs/ARCHITECTURE.md` now lists `check-supervisor-orchestration.sh` alongside the other nine scripts the paired workflow entry points run, in the same position the entry points use. The overlay runbook's fixture-coverage paragraph now also states that the empty-tier fixture removes two members' `agentCapabilityMatrix` entries, so the sentence describes what the fixture actually mutates rather than only the tier that empties.
- Reason: code review of the entry above recorded that `docs/ARCHITECTURE.md` enumerated nine of the ten checks, so the source-of-truth architecture doc understated the validation pipeline that the supervisor-orchestration overlay had already extended, and the runbook's fixture coverage sentence had stopped matching the fixture.
- Affected files: docs/ARCHITECTURE.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-12 - Cover the fixture's entry-absent branch and sort the PowerShell fixture enumeration"
- Review status: pending-review
- Discrepancies or follow-up: the extended list is still a documentation enumeration and no validator reads `docs/ARCHITECTURE.md`, so it can drift again; pinning it was left out of this slice deliberately to keep the change bounded. The earlier entries in this log remain `pending-review` and still need independent re-review. ADR 0003 remains `Proposed`.

### 2026-09-12 - Correct the non-mutating tier's derivation source and pin the claim

- Area: overlay ADR, overlay runbook
- Change type: docs, adr, runbook
- Summary: both design documents now state that the non-mutating delegation tier is derived from each agent's `tools` frontmatter, and that the frontmatter scan is the authoritative side, which the overlay checks cross-check against `agentCapabilityMatrix` in `.github/roles/tool-access.json`. Both previously said the tier was derived from `agentCapabilityMatrix`, which is the opposite of what the paired validators do and of the authority ordering the sole-holder invariant states. The surrounding paragraphs, including the non-emptiness assertion and the exception path, are unchanged.
- Reason: code review of the entry below returned `needs-revision` with W1: the two sentences contradicted `check-supervisor-orchestration.sh`, which iterates the frontmatter scan and never the matrix, and contradicted `CHANGELOG.md`, which records the frontmatter derivation as deliberate so that a removed matrix entry cannot shrink the tier. The contradiction was reachable in the same repository state the tier fixture now tolerates, because the frontmatter/matrix agreement check is skipped for an agent whose matrix entry is absent.
- Affected files: docs/adr/0003-supervisor-orchestration-overlay.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-12 - Harden the non-mutating tier fixture and pin the tier's frontmatter derivation"
- Review status: pending-review
- Discrepancies or follow-up: the corrected sentences are now pinned by paired text assertions on both platforms (`derived tier is non-empty`), which closes S2 from the same review, so this drift class cannot recur silently here. ADR 0003 remains `Proposed`. The prior entries in this log stay `pending-review`; this entry corrects their content and does not clear that status, which needs independent re-review. The `orchestration-coordinator` role-id framing and the `evals/tasks/problem-structuring.md` manifest gap recorded earlier both remain open.

### 2026-09-11 - Document the non-empty non-mutating tier assertion

- Area: overlay ADR, overlay runbook
- Change type: docs, adr, runbook, policy
- Summary: recorded the second half of the capability-scoped preconditions decision. The runbook's "What An Unverified Result Allows" section now states that both paired validators assert the derived non-mutating tier is non-empty, that this keeps a later edit from silently reducing the capability-scoped rule to the total block the runbook says it is not, and that the assertion proves the tier exists rather than that it was used. The "Validating The Overlay Assets" section adds the tier's non-emptiness to the list of checked facts, raises the fixture count from sixteen to seventeen, and names the new case. ADR 0003's Operational impacts states the same boundary, its closing paragraph on static observability now says the validators assert only that the fallback tier is defined and non-empty, and its required validation activities list the empty-tier case alongside the other negative fixtures.
- Reason: the entry below recorded the L2 decision without recording that the decision's fallback tier was unverified. The rule depends on a non-mutating tier existing, so leaving it unasserted meant a reader could treat the tier as guaranteed when nothing checked it, and a later edit could remove it without any gate going red.
- Affected files: docs/adr/0003-supervisor-orchestration-overlay.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-11 - Assert the non-mutating delegation tier is non-empty"
- Review status: pending-review
- Discrepancies or follow-up: the documentation states explicitly that the assertion is a definition check and not an enforcement claim, because the surrounding section forbids describing the tier as an enforced restriction. ADR 0003 stays `Proposed` pending maintainer acceptance, so no repo is bound by it yet. The `orchestration-coordinator` role-id framing that an earlier entry escalated to `architecture-reviewer` is untouched here, and the unrelated pre-existing eval-manifest gap (`evals/tasks/problem-structuring.md` listed but absent from the `check-evals.sh` required-file list) remains open.

### 2026-09-11 - Document the scoped frontmatter obligation and the widened approval-gate wording guard

- Area: overlay runbook
- Change type: docs, runbook, policy
- Summary: rewrote the runbook's description of what the validators check so that it matches the code. The approval-gate wording guard now covers the agent catalog, every agent file, and the role, scope, and intent strings in `tool-access.json`; the `agentRoleHints` agreement with the capability matrix is named; and the matrix tool vocabulary is described as checked in both directions. Added a paragraph stating that the `tools` frontmatter obligation is scoped to agents registered in `agentCapabilityMatrix`, that a file declaring `delegate-agent` is caught whether or not it is registered, and that an unregistered agent file without a `tools` list is out of scope. Expanded the fixture list to all sixteen cases and replaced the audit-log-copy note, which described a copy that no longer carries the log, with the pruning behavior. This closes the M1 residual recorded in the entry below: the three shipped strings that still described the approval gate as enforcement have been reworded, and the guard that missed them now sees them.
- Reason: reviewer findings F1 through F8 from the code review of the previous change. The runbook is the adopter-facing description of the validation surface, so leaving it describing pre-change behavior would have re-created the same documentation-versus-code drift this change set out to close, and the audit-log note would have described handling that no longer happens.
- Affected files: docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-11 - Scope the supervisor frontmatter obligation and widen the enforcement-framing guard"
- Review status: pending-review
- Discrepancies or follow-up: the runbook still records `orchestration-coordinator` as having no matching core role id, which the review found inaccurate; the wording is escalated to `architecture-reviewer` because the correct framing is a role-model decision, not a documentation edit. ADR 0003 stays `Proposed` pending maintainer acceptance. The unrelated pre-existing gap recorded in earlier entries (`evals/tasks/problem-structuring.md` listed in the manifest but absent from `check-evals.sh` required files) remains open.

### 2026-09-11 - Scope the hook-inheritance enablement precondition to delegation capability

- Area: overlay ADR, overlay runbook
- Change type: adr, runbook, policy
- Summary: settled the enablement-precondition question left open by the architecture review. Both ADR 0003 and `docs/runbooks/supervisor-orchestration.md` previously stated that an unverifiable hook-inheritance result must be recorded "rather than enabling the overlay on an assumed control", without saying what is permitted once the gap is recorded. Both now state that the precondition is capability-scoped rather than overlay-wide: verified hook inheritance permits the full `specialistAllowList`, and unverified or unverifiable hook inheritance restricts delegation to the non-mutating tier, defined as agents whose declared capabilities are a subset of `read`, `search`, and `todo` (currently `architecture-reviewer`, `code-reviewer`, and `security-reviewer`). Added a "What An Unverified Result Allows" section to the runbook, extended ADR 0003's Operational impacts with the same rule and its rationale, added the maintainer-approved exception path for teams that need mutating delegation without the evidence, and extended ADR 0003's required validation activities so the scoping consequence is explicit there too.
- Reason: L2 escalation from the architecture review on 2026-09-11, which asked whether failing the hook-inheritance check blocks enablement outright or is accepted with compensating controls recorded. The answer is neither: a total block would also remove delegation that carries no `preToolUse`-relevant exposure, since the supervisor holds no `edit` and no `execute` and only the worker's capability creates the risk that the hook guards. Scoping the block to mutating delegation keeps the complex workflow's parallel read-only analysis stage available while still refusing every delegation that could mutate state unguarded.
- Affected files: docs/adr/0003-supervisor-orchestration-overlay.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-11 - Close the supervisor sole-holder coverage gap and add delegation enablement preconditions"
- Review status: pending-review
- Discrepancies or follow-up: one item remains open, with the review findings this entry adjudicated now closed. (1) The review's M2 and M2b findings, and its L2 documentation gap, are already closed on disk: `check-supervisor-orchestration.sh` glob-scans every `.github/agents/*.agent.md` frontmatter, cross-checks frontmatter against `agentCapabilityMatrix` in both directions, rejects a `specialistAllowList` that lists a delegation-capable agent, and carries negative fixtures `worker-frontmatter-delegation`, `unregistered-delegation-holder`, and `allow-list-delegation-holder`. The review's line citations no longer match the file, so the review predates that remediation. (2) The M1 residual was live when this entry was written and is closed by the entry above: `.github/agents/delegation-supervisor.agent.md:2` and `:9` and `.github/roles/tool-access.json:53` said at the time that the supervisor "enforce[s] the high-risk approval boundary", while `tool-access.json:179` says the same gate is "not enforcement". The literal-string guard for `high-risk approval enforcement` did not match those three phrasings. (3) ADR 0003 remains `Proposed` and needs maintainer acceptance. Also note the earlier entry "Correct supervisor approval-gate documentation framing" describes the two fields it corrected accurately, but its scope was narrower than it reads: the `roles.orchestration.intent` string in the same file was not corrected.

### 2026-09-11 - Document supervisor delegation-boundary coverage and enablement preconditions

- Area: overlay runbook, ADR, schema reference
- Change type: docs, adr, runbook, policy
- Summary: rewrote the runbook's validation-coverage paragraph, which claimed the sole-holder check does not scan every agent file's frontmatter, to describe the check that now does and to name the one boundary that remains. Expanded the fixtures list to all eleven cases. Added an Enablement Preconditions section under How To Enable and a hook-inheritance paragraph under Supported Runtimes, both stating that hook inheritance for delegated subagents must be verified and recorded before the overlay is relied on. Recorded the `serializedReason` v1 optionality in the write-set discipline section and the fixture harness's temporary audit-log copy in the validation section. Extended ADR 0003's operational impacts with the two enablement preconditions and its required validation activities with the hook-inheritance confirmation.
- Reason: M2 and L2 from the architecture review. The runbook documented the sole-holder coverage limit, but the limit was closable, and hook inheritance was an undefined obligation in an ADR that already required a delegation-boundary security review. Because the overlay's entire safety posture rests on readers not mistaking a behavioral contract for an enforced control, the enablement preconditions needed to be stated in the documents an adopter reads, not left implicit.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md, .github/schema/delegation-plan.schema.json
- Related code: CHANGELOG.md entry "2026-09-11 - Close the supervisor sole-holder coverage gap and add delegation enablement preconditions"
- Review status: pending-review
- Discrepancies or follow-up: ADR 0003 stays `Proposed` pending maintainer acceptance. The runbook now records one deliberate coverage boundary rather than two implicit gaps: general agent-file registration in `agentCapabilityMatrix` is not enforced, because `orchestration-coordinator` has no core role id and registering it is a role-model decision outside this overlay. Whether hook-inheritance evidence should be machine-checkable, or must stay a human enablement obligation, remains an architecture-review question. The unrelated pre-existing gap recorded in earlier entries (`evals/tasks/problem-structuring.md` listed in the manifest but absent from `check-evals.sh` required files) remains open.

### 2026-09-11 - Correct supervisor approval-gate documentation framing

- Area: agent catalog, role source of truth, overlay runbook, schema reference
- Change type: docs, policy, reference
- Summary: corrected the two shipped governance texts that described the supervisor's high-risk approval gate as enforcement. The `delegation-supervisor` row in the `.github/AGENTS.md` ownership map and the `delegation-supervisor` scope in `.github/roles/tool-access.json` now state that the gate is a prompt-level contract, not enforcement, matching `.github/roles/orchestration-policy.json`, ADR 0003, and the overlay runbook. Added the prompt-level caveat and a `docs/runbooks/supervisor-orchestration.md` pointer to the supervisor's agent-catalog entry and to the orchestration pointer line at the end of the agent catalog, because the file making the claim previously contained no reference to the caveat. Updated `docs/runbooks/supervisor-orchestration.md` so its validation section lists the newly asserted facts, adds the two new negative fixtures, and states plainly that the sole-holder check reads the `roles` map and `agentCapabilityMatrix` plus the supervisor frontmatter only, rather than implying coverage of every agent file. Recorded the narrow write-set facts the machine now checks in the write-set discipline section, and described the boundedness rule in `delegation-plan.schema.json`.
- Reason: a code review found that the agent catalog an adopter is most likely to read described a control the repository's own canonical policy says does not exist, with no pointer to the caveat, and that the runbook's coverage description implied broader sole-holder validation than the checks perform. Documentation accuracy mattered here because the entire overlay safety posture depends on readers not mistaking a behavioral contract for an enforced control.
- Affected files: .github/AGENTS.md, .github/roles/tool-access.json, docs/runbooks/supervisor-orchestration.md, .github/schema/delegation-plan.schema.json
- Related code: CHANGELOG.md entry "2026-09-11 - Correct the supervisor approval-gate framing and close two validation gaps"
- Review status: pending-review
- Discrepancies or follow-up: ADR 0003 stays `Proposed` pending maintainer acceptance. The runbook now documents two known coverage limits rather than leaving them implicit: the sole-holder check does not scan every agent's frontmatter, and hook inheritance for delegated subagents is unverified. Whether to close the first gap and whether hook-inheritance evidence should gate overlay enablement are architecture-review decisions, not documentation ones. The pre-existing gap recorded in the previous entry (`evals/tasks/problem-structuring.md` listed in the manifest but absent from `check-evals.sh` required files) is unrelated and remains open.

### 2026-09-11 - Document supervisor orchestration validation coverage

- Area: runbooks, ADR
- Change type: docs, runbook, adr, reference
- Summary: updated `docs/runbooks/supervisor-orchestration.md` so its validation section matches what the checks actually cover. The section now lists the deterministic facts both validators assert, including the delegation depth, the write-set and enforcement flags, the agent frontmatter, and validation of the delegation-plan example against `delegation-plan.schema.json`; it documents the negative fixtures the validators run; and it states that the repo-local checks evaluate only the JSON Schema subset this schema uses, with the full `python -m jsonschema` and `ajv-cli` commands for independent validation, mirroring the approval-gated handoff runbook. Updated ADR 0003 so its Validation section states that it lists required activities rather than completed work, notes that the three named failure modes are now exercised as negative fixtures, softens the "structurally incapable of direct mutation" claim to a declared no-`edit`/no-`execute` capability with an unverified platform mapping for `delegate-agent`, and records that the paired validators and both workflow entry points were executed on 2026-09-11.
- Reason: a code review found that the runbook's coverage description was accurate but silent about the missing fixtures, that the schema was never validated against its worked example, and that the ADR's capability claim overstated a declared property. The documentation had to distinguish required validation activities from executed ones and stop implying enforcement the repository does not provide.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md
- Related code: CHANGELOG.md entry "2026-09-11 - Remediate supervisor orchestration validator gaps"
- Review status: pending-review
- Discrepancies or follow-up: ADR 0003 stays `Proposed` and still needs maintainer acceptance because the overlay edits two core modules. Independent `security-reviewer`, `code-reviewer`, and `qa` passes remain outstanding before any repo enables the overlay. A pre-existing, unrelated gap was left in place: `evals/tasks/problem-structuring.md` and its checklist exist and are listed in the module manifest but are absent from the `required_files` list in `.github/scripts/check-evals.sh`.

### 2026-09-11 - Document supervisor orchestration overlay implementation

- Area: runbooks, agents, ADR, README, reference docs
- Change type: docs, runbook, adr, reference
- Summary: documented the implemented supervisor orchestration overlay. Added `docs/runbooks/supervisor-orchestration.md` covering the two orchestration roles and their difference, enablement, disabled-state behavior, one-level delegation depth, the eleven simple-versus-complex routing criteria, the approval categories and the prompt-level caveat, write-set discipline, the runtime mapping for `delegate-agent`, the guided-delegation fallback, and what static validation cannot prove. Registered the runbook in `docs/runbooks/INDEX.md` in both lists. Added the supervisor delegation flow and the `delegation-supervisor` handoff-memory field to `agentic-dev.md`, a supervisor overlay subsection to `starter-composition.md`, a delegation row to `tool-surface-matrix.md`, the `overlay-supervisor-orchestration` node and edge to `ARCHITECTURE.md`, migration guidance to `MIGRATION.md`, and an overlay summary plus validation command to `README.md`. Updated ADR 0003 to record the settled agent name, the canonical `orchestration-policy.json` source, the routing criteria, and the specialist allow-list.
- Reason: a maintainer must be able to understand what the overlay does, how to enable it, what changes when it is disabled, how it differs from `orchestration-coordinator`, and where its limits are, without overstating platform guarantees.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/runbooks/INDEX.md, docs/runbooks/agentic-dev.md, docs/runbooks/starter-composition.md, docs/runbooks/tool-surface-matrix.md, docs/ARCHITECTURE.md, docs/adr/0003-supervisor-orchestration-overlay.md, MIGRATION.md, README.md
- Related code: CHANGELOG.md entry "2026-09-11 - Implement supervisor orchestration overlay"
- Review status: pending-review
- Discrepancies or follow-up: the runbook states that the approval gate is a behavioral contract rather than enforced authorization, and that static validation cannot prove runtime properties. Documentation review by a maintainer is still pending, as is ADR 0003 acceptance.

### 2026-09-11 - Record proposed supervisor orchestration overlay decision

- Area: ADR, docs
- Change type: adr, policy, reference
- Summary: added `docs/adr/0003-supervisor-orchestration-overlay.md` as a `Proposed` ADR recording the supervisor orchestration overlay decision. The ADR adopts the self-contained gate (Option B) for v1, rejects the hard dependency on `overlay-approval-gated-orchestration` (Option A), and defers promoting a minimum high-risk approval gate into core (Option C) to a separate proposal and ADR. It also records the new `orchestration` role, the `delegate-agent` capability, the sole-holder and no-nesting rules, the declared write-set contract with serialize-when-unknown fallback, the explicit "prompt-level contract, not enforcement" caveat, and the finding that implementation edits two core modules (`AGENTS.md` in `core-agents`, `tool-access.json` in `core-governance`).
- Reason: an independent architecture review of the overlay packet returned pass-with-conditions. The direction was accepted, but the review required the safety framing to be corrected, the high-risk category list to be single-sourced, and the file/change list to be expanded before implementation. Recording the decision in an ADR keeps the deferred core change (Option C) separate from this overlay rather than bundling a core-wide safety change into an optional module.
- Affected files: docs/adr/0003-supervisor-orchestration-overlay.md, DOC-CHANGELOG.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: ADR 0003 is `Proposed` and needs maintainer acceptance before it is binding; the change edits two core modules, so it carries a starter-wide consensus gate. Open items carried forward from the review: the simple-versus-complex routing criterion, the exact validator scope, and the deferred Option C proposal. Those items were settled and implemented on 2026-09-11; see the "2026-09-11 - Document supervisor orchestration overlay implementation" entry for the artifacts that were subsequently added.

### 2026-09-10 - Document Phaser game development overlays, runbook, and examples

- Area: instructions, prompts, skills, runbooks, architecture docs, examples, README
- Change type: docs, runbook, policy, reference
- Summary: documented a new game development capability for the starter. Added `docs/runbooks/game-dev.md` covering overlay composition, the `app/game/` layout with the `assets/masters` versus `assets/runtime` split, the asset storage decision and its CI consequence, the prompt-to-task mapping, the client-trust boundary, and when not to use the overlays. Added `docs/adr/0002-game-asset-storage-policy.md` recording the proposed starter-wide asset storage policy: directory-scoped masters, regenerable runtime assets, no extension-scoped large-file rules, and no change to the core `.gitattributes`. Added two example addenda, `.github/examples/game-dev/gitattributes.addendum` (binary and large-file handling plus the `-text` rationale for overriding the starter's `* text=auto eol=lf`) and `.github/examples/game-dev/gitignore.addendum` (commented engine blocks for Phaser/Vite, Unity, Unreal, and Godot, plus signing-material ignores). Added a "Game development repos" section to `starter-composition.md`, a game overlays row to the `adopting-existing-github.md` artifact checklist, `game-perf-triage` examples to `skills.md`, the runbook to `INDEX.md` in both the day-to-day list and the quick reference table, and `overlay-game-core` / `overlay-game-phaser` nodes to the `ARCHITECTURE.md` module dependency graph. Updated the README overlay, prompt, skill, hook, and eval sections.
- Reason: the starter had no game development documentation, and the asset storage decision plus the binary-file interaction with the repository's LF normalization policy were undiscoverable from the existing docs.
- Affected files: docs/runbooks/game-dev.md, docs/adr/0002-game-asset-storage-policy.md, docs/runbooks/starter-composition.md, docs/runbooks/adopting-existing-github.md, docs/runbooks/skills.md, docs/runbooks/INDEX.md, docs/ARCHITECTURE.md, README.md, .github/examples/game-dev/gitattributes.addendum, .github/examples/game-dev/gitignore.addendum
- Related code: CHANGELOG.md entry "2026-09-10 - Add Phaser game development overlays, prompts, skill, evals, and guardrails"
- Review status: pending-review
- Discrepancies or follow-up: ADR 0002 is `Proposed` and needs maintainer acceptance before it is binding. The gitattributes and gitignore addenda are examples only and are not active in this repository, so they are not validated by any check script, and no validator enforces the asset storage policy by design.

### 2026-09-04 - Clarify changelog clearing during project initialization

- Area: prompts, runbooks
- Change type: docs, policy, reference
- Summary: strengthened the `initialize-new-project` prompt so it explicitly removes ALL starter entries from `CHANGELOG.md` and `DOC-CHANGELOG.md` when initializing a new project, keeps only the header and entry template, and adds a single template-compliant initial entry per log; strengthened the README deliverable so all starter content is cleared and replaced with a fresh project README; added a matching safety boundary and a note that starter history must never remain; aligned the starter-adoption runbook cleanup step with the same wording.
- Reason: the starter's own development history must not leak into downstream projects; `CHANGELOG.md` belongs to code changes made for the initialized project only.
- Affected files: .github/prompts/initialize-new-project.prompt.md, docs/runbooks/starter-adoption.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-09-04 - Document runtime overlay scoping

- Area: instructions, runbooks
- Change type: docs, policy, reference
- Summary: documented that the Hermes and Honcho instruction overlays attach in VS Code only when marker files exist (`.hermes/` and `honcho.*` or `.honcho/` respectively), and noted the pinned instruction-file setting in `.vscode/settings.json`; added matching activation notes to the Hermes and Honcho runbooks.
- Reason: the optional runtime overlays previously used `**/*` and injected rules into every prompt, conflicting with their default-disabled module status.
- Affected files: .github/instructions/hermes-runtime.instructions.md, .github/instructions/honcho-memory.instructions.md, docs/runbooks/hermes-runtime.md, docs/runbooks/honcho-memory.md
- Related code: CHANGELOG.md entry "2026-09-04 - Scope runtime overlays and pin Copilot instruction setting"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-09-04 - Document frontend and backend technique guidance

- Area: instructions, frontend, backend
- Change type: docs, policy, reference
- Summary: documented new technique sections in the frontend overlay (data fetching and async, forms, security) and the backend overlay (concurrency and I/O, security) plus expanded API, data, error-handling, and testing guidance; these are framework-agnostic rules that the React/Next.js and FastAPI overlays layer on top of.
- Reason: give agents concrete, actionable best-practice rules for the two most common coding surfaces.
- Affected files: .github/instructions/frontend.instructions.md, .github/instructions/backend.instructions.md
- Related code: CHANGELOG.md entry "2026-09-04 - Add technique guidance to frontend and backend overlays"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-09-04 - Document guardrail, instruction, and prompt hardening

- Area: instructions, runbooks, prompts, architecture docs
- Change type: docs, policy, reference
- Summary: added a CI/CD workflow instruction overlay covering action pinning, least-privilege permissions, and secret hygiene; documented new blocked hook patterns, fixture coverage, and the scoped case-sensitivity rule for hook patterns in the hooks runbook; added CI overlay composition guidance in the starter composition runbook, a CI overlay row in the adopting-existing-github artifact checklist, and overlay nodes in the ARCHITECTURE module dependency graph (including the previously missing `overlay-static-prototype` node); added validation-evidence and regression-test rules to core Delivery; documented the new `fix-bug` and `add-policy-rule` prompts in the README.
- Reason: close instruction, prompt, and guardrail coverage gaps for a coding-first workflow and keep docs aligned with the new rules and assets.
- Affected files: .github/instructions/core.instructions.md, docs/runbooks/hooks.md, docs/runbooks/starter-composition.md, docs/runbooks/adopting-existing-github.md, docs/ARCHITECTURE.md, README.md
- Related code: CHANGELOG.md entry "2026-09-04 - Harden hooks, prompt contracts, and add CI workflow overlay"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-09-04 - Add Bootstrap CSS usage rules to static prototype overlay

- Area: instructions, runbooks
- Change type: reference
- Summary: added a Bootstrap CSS Usage section to the static-prototype overlay (utility-first styling, custom CSS boundary, variable-based theming, breakpoints, forms, JS components, and icons) and extended the runbook with a pinned Bootstrap Icons CDN line and a :root variable override example.
- Reason: the overlay governed layout discipline but not custom CSS, theming, or component usage.
- Affected files: .github/instructions/static-prototype.instructions.md, docs/runbooks/static-prototypes.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-09-04 - Add visual quality guard rails to static prototype overlay

- Area: instructions, runbooks
- Change type: reference
- Summary: added a Visual Quality and Layout Discipline section to the static-prototype overlay (Bootstrap spacing, layout, alignment, type, color, and component rules plus a pre-finish visual lint) and a matching visual check list to the static prototypes runbook.
- Reason: prototypes were coming back functionally correct but visually inconsistent; the overlay lacked layout discipline rules.
- Affected files: .github/instructions/static-prototype.instructions.md, docs/runbooks/static-prototypes.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-09-04 - Add static prototype overlay and runbook

- Area: instructions, runbooks
- Change type: reference
- Summary: added an opt-in `static-prototype` instruction overlay for throwaway HTML + Bootstrap + HTMX presentation prototypes, registered `overlay-static-prototype` in `starter-modules.json`, added `docs/runbooks/static-prototypes.md` with pinned-CDN, mock-interactivity, and Netlify deployment guidance, and linked it from the runbook index and composition runbook.
- Reason: no existing overlay covered plain-HTML prototyping or static hosting; agents defaulted to build-heavy production patterns for presentation-only mockups.
- Affected files: .github/instructions/static-prototype.instructions.md, .github/starter-modules.json, docs/runbooks/static-prototypes.md, docs/runbooks/INDEX.md, docs/runbooks/starter-composition.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-19 - Refresh README title for August 2026

- Area: README
- Change type: docs
- Summary: updated the README heading from "(VS Code, June 2026 Workflow)" to "(VS Code, August 2026 Workflow)" so the public-facing title reflects the current month.
- Reason: the title still said June 2026.
- Affected files: README.md
- Related code: None
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-08-18 - Fix markdown quality failures in docs and examples

- Area: docs, examples, runbooks
- Change type: docs, fix
- Summary: fixed broken relative links in `.github/examples/README.md` (8 links corrected to `../../docs/runbooks/...`) and `docs/runbooks/INDEX.md` (6 links corrected to `../../...`); removed trailing whitespace in `docs/ARCHITECTURE.md` (inside Mermaid fences), `docs/runbooks/module-manifest-versioning.md`, and `TROUBLESHOOTING.md`.
- Reason: `bash .github/scripts/check-starter-workflow.sh` failed at the Markdown quality check with broken-link and trailing-whitespace errors.
- Affected files: .github/examples/README.md, docs/runbooks/INDEX.md, docs/ARCHITECTURE.md, docs/runbooks/module-manifest-versioning.md, TROUBLESHOOTING.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-18 - Document Laravel component eval golden task

- Area: evals
- Change type: docs, reference
- Summary: added `evals/tasks/laravel-component.md` and `evals/expected/laravel-component.checklist.md` covering a Livewire component change that must honor the PHP, Laravel, Livewire, Alpine, and database instruction overlays and consult official docs for installed versions; updated the README eval task list.
- Reason: close the eval coverage gap for the newly added PHP/Laravel stack overlays.
- Affected files: evals/tasks/laravel-component.md, evals/expected/laravel-component.checklist.md, README.md
- Related code: CHANGELOG.md entry "2026-08-18 - Add Laravel component eval golden task and checklist"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-18 - Refresh overlay catalog references in README and migration guide

- Area: README, migration guide
- Change type: docs, reference
- Summary: updated the README overlay summary to mention PHP/Laravel ecosystem and database overlays; expanded the migration guide's "Add Stack-Specific Instructions" step with PHP/Laravel ecosystem and database instruction overlays.
- Reason: keep the starter's overlay catalog references current after adding PHP, Laravel, Filament, Livewire, Inertia, Alpine, Valkey, SQLite, PostgreSQL, and MariaDB overlays.
- Affected files: README.md, MIGRATION.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-18 - Document ui-scaffold skill alignment

- Area: skills, runbooks
- Change type: docs, reference
- Summary: updated `ui-scaffold` skill guidance to read active UI instruction overlays and official documentation before scaffolding; added Livewire, Inertia, Alpine, and Filament trigger examples and overlay/doc-compliance checklist items; added matching example prompts to `docs/runbooks/skills.md`.
- Reason: keep the ui-scaffold skill consistent with the PHP/Laravel UI stack overlays and the doc-first rules.
- Affected files: .github/skills/ui-scaffold/SKILL.md, docs/runbooks/skills.md
- Related code: CHANGELOG.md entry "2026-08-18 - Align ui-scaffold skill with stack instruction overlays"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-18 - Document database instruction overlays

- Area: instructions, runbooks, architecture docs
- Change type: docs, policy, reference
- Summary: added instruction overlays for SQLite, PostgreSQL, and MariaDB, each scoped by `applyTo` with official documentation references and latest-stable/doc-first version rules; added a "Relational database repos" section to `starter-composition.md`, a database overlays row to the `adopting-existing-github.md` artifact checklist, and overlay modules to the `ARCHITECTURE.md` module dependency graph.
- Reason: database-specific guidance was missing from the optional overlay catalog.
- Affected files: .github/instructions/sqlite.instructions.md, .github/instructions/postgresql.instructions.md, .github/instructions/mariadb.instructions.md, docs/runbooks/starter-composition.md, docs/runbooks/adopting-existing-github.md, docs/ARCHITECTURE.md
- Related code: CHANGELOG.md entry "2026-08-18 - Add database instruction overlays for SQLite, PostgreSQL, and MariaDB"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-18 - Document PHP ecosystem instruction overlays

- Area: instructions, runbooks, architecture docs
- Change type: docs, policy, reference
- Summary: replaced the mislabeled Laravel overlay (a Python/SQL backend copy) with Laravel-specific guidance; added six new instruction overlays for PHP 8+, Filament 5+, Livewire 4+, Inertia.js, Alpine.js, and Valkey, each scoped by `applyTo` and pointing to official documentation with latest-stable/doc-first version rules; added a "PHP / Laravel repos" section to `starter-composition.md`, PHP/Laravel rows to the `adopting-existing-github.md` artifact checklist, and new overlay modules to the `ARCHITECTURE.md` module dependency graph.
- Reason: the PHP/Laravel ecosystem had no instruction coverage and the existing `laravel.instructions.md` contained unrelated Python/SQL content that was never registered in the module manifest.
- Affected files: .github/instructions/laravel.instructions.md, .github/instructions/php.instructions.md, .github/instructions/filament.instructions.md, .github/instructions/livewire.instructions.md, .github/instructions/inertia.instructions.md, .github/instructions/alpine.instructions.md, .github/instructions/valkey.instructions.md, docs/runbooks/starter-composition.md, docs/runbooks/adopting-existing-github.md, docs/ARCHITECTURE.md
- Related code: CHANGELOG.md entry "2026-08-18 - Add PHP ecosystem instruction overlays and fix the Laravel overlay"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-08 - Document LTS-first and documentation-driven dependency rules

- Area: instructions, core, security, backend, frontend
- Change type: docs, policy
- Summary: added "Dependencies and Documentation" section to `core.instructions.md` establishing baseline rules for LTS releases, official documentation consultation, citation of references, and verification against current docs; added LTS preference, CVE/advisory checking, and security-docs consultation to `security.instructions.md` supply chain rules; expanded `backend.instructions.md` Dependency and Runtime Hygiene with LTS Python/library guidance, documentation-first rules, and advisory checking; added new "Dependencies" section to `frontend.instructions.md` covering LTS Node.js, official docs consultation, citation of references, and breaking-change/advisory awareness.
- Reason: ensure agents consistently prefer latest stable LTS versions, consult and cite official documentation (not memory or AI-generated examples), and check for security advisories and deprecations before using any dependency — applied at core, security, backend, and frontend layers.
- Affected files: .github/instructions/core.instructions.md, .github/instructions/security.instructions.md, .github/instructions/backend.instructions.md, .github/instructions/frontend.instructions.md
- Related code: CHANGELOG.md entry "2026-08-08 - Add LTS-first and documentation-driven dependency rules across instructions"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-08-08 - Document instruction file improvements

- Area: instructions, security, frontend, memory
- Change type: docs, policy
- Summary: added intro paragraph to `security.instructions.md` stating its role as the always-applied OWASP-aligned baseline; added "Error Handling" section to `frontend.instructions.md` with guidance on error boundaries, console hygiene, and not exposing internals; split `frontend.instructions.md` "Quality" into separate "Testing" and "Accessibility" sections matching the React overlay's structural pattern; added cross-reference from `core.instructions.md` Safety to `security.instructions.md`; added cross-reference from `honcho-memory.instructions.md` to `memory.instructions.md` for the three-layer model.
- Reason: audit across all 12 instruction files identified missing content (security intro, frontend error handling), structural inconsistency (frontend Quality mixing concerns), and missing cross-references that reduce agent navigability of the layered instruction model.
- Affected files: .github/instructions/security.instructions.md, .github/instructions/frontend.instructions.md, .github/instructions/core.instructions.md, .github/instructions/honcho-memory.instructions.md
- Related code: CHANGELOG.md entry "2026-08-08 - Improve instruction file coverage and cross-references"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-07-25 - Document clone-as-template adoption path and initialize-new-project prompt

- Area: runbooks, onboarding, quickstart, prompts
- Change type: docs, onboarding, reference
- Summary: added a "Clone-As-Template (New Project Quickstart)" section to `starter-adoption.md` documenting the clone→rename→add-app-code adoption path, including a first-prompt step that describes how to use the new `initialize-new-project` prompt to adapt all documentation to a specific project; added `app/` directory convention for separating application code from workflow assets; created `.github/prompts/initialize-new-project.prompt.md` — a reusable prompt that rewrites README, resets changelogs, enables/disables stack overlays, and preserves workflow governance assets; registered the new prompt in `starter-modules.json`; updated `QUICKSTART.md` alternative-path note to mention the initialization prompt.
- Reason: the starter only documented copying `.github/` into existing repos; users who clone the starter as a template need both the clone steps and a guided way to adapt all documentation to their specific project name, tech stack, and goals.
- Affected files: docs/runbooks/starter-adoption.md, QUICKSTART.md, .github/prompts/initialize-new-project.prompt.md, .github/starter-modules.json
- Related code: CHANGELOG.md entry "2026-07-25 - Document clone-as-template adoption path and initialize-new-project prompt"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-07-18 - Document problem-structuring enrichment from McKinsey Mind

- Area: skills, prompts, evals
- Change type: docs, runbook, reference
- Summary: enriched the `problem-structuring` skill documentation with concepts from *The McKinsey Mind* (Rasiel & Friga): added Core Principles covering fact-based hypothesis-driven discipline, intuition-data balance with three-tier evidence classification (data-backed, intuition-backed, assumption), one-day answer discipline, and key-driver focus; reframed Step 1 around initial hypothesis formation at the framing stage (before decomposition); added key-driver identification throughout structuring and prioritization; renamed and deepened Step 4 into analysis design with confirm/refute framing; split evidence gathering and interpretation into distinct phases with the "so what?" test; expanded communication guidance to include audience-specific buy-in and explicit decision asks; updated the eval checklist (from 7 sections to 10, from 39 to 61 criteria) and eval task to match the enriched method; updated the `structure-technical-problem` prompt with new deliverables, safety boundaries, and output sections.
- Reason: incorporate deeper problem-solving discipline from the McKinsey Mind framework to improve the skill's rigor without adding complexity.
- Affected files: .github/skills/problem-structuring/SKILL.md, .github/prompts/structure-technical-problem.prompt.md, evals/tasks/problem-structuring.md, evals/expected/problem-structuring.checklist.md
- Related code: CHANGELOG.md entry "2026-07-18 - Enrich problem-structuring skill with McKinsey Mind book insights"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-07-17 - Add problem-structuring skill, prompt, and agent enhancements

- Area: skills, prompts, agents, runbooks, eval harness
- Change type: docs, runbook, reference
- Summary: added `problem-structuring` skill documentation adapting McKinsey's 7-step problem-solving method for software engineering; added `structure-technical-problem` prompt with structured deliverables; added eval task and expected checklist for problem-structuring behavior; updated `analyst` agent to reference the skill and hypothesis-driven investigation; updated `tech-planner` agent to reference MECE decomposition, Pyramid Principle synthesis, and SCQA communication; updated `docs/runbooks/skills.md` with example prompts for the new skill; registered new assets in `starter-modules.json` under workflow-skills, workflow-prompts, and workflow-evals.
- Reason: improve the repo's problem-solving workflow by incorporating McKinsey-style structured decomposition and synthesis into the agent chain.
- Affected files: .github/skills/problem-structuring/SKILL.md, .github/prompts/structure-technical-problem.prompt.md, .github/agents/analyst.agent.md, .github/agents/tech-planner.agent.md, docs/runbooks/skills.md, evals/tasks/problem-structuring.md, evals/expected/problem-structuring.checklist.md, .github/starter-modules.json
- Related code: CHANGELOG.md entry "2026-07-17 - Add McKinsey problem-structuring skill, prompt, and evals"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-06-20 - Complete high-priority documentation
- Change type: docs, reference
- Summary: created MIGRATION.md with comprehensive v1.0 to v1.1 migration guide; created .github/examples/README.md documenting example usage patterns; created docs/runbooks/module-manifest-versioning.md explaining module manifest versioning strategy; created docs/ARCHITECTURE.md with Mermaid diagrams showing module relationships, validation workflows, and security layers.
- Reason: complete remaining high-priority documentation items to improve onboarding, migration, and understanding of the starter's architecture.
- Affected files: MIGRATION.md, .github/examples/README.md, docs/runbooks/module-manifest-versioning.md, docs/ARCHITECTURE.md
- Related code: CHANGELOG.md entry "2026-06-20 - Complete high-priority documentation"
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-06-20 - Add developer experience documentation

- Area: onboarding, troubleshooting, navigation
- Change type: docs, reference
- Summary: created QUICKSTART.md with 5-minute setup guide; created TROUBLESHOOTING.md with common issues and solutions; added table of contents to README.md; created docs/runbooks/INDEX.md to organize runbooks by use case.
- Reason: improve onboarding experience and make it easier for users to find relevant documentation and resolve common issues.
- Affected files: QUICKSTART.md, TROUBLESHOOTING.md, README.md, docs/runbooks/INDEX.md
- Related code: CHANGELOG.md entry "2026-06-20 - Implement high-priority efficiency improvements"
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-06-07 - Expand README starter composition details

- Area: README composition and adoption guidance
- Change type: docs, reference
- Summary: added a README section that explains how the starter is split across core rules, optional overlays, reusable agents and skills, hook guardrails, disabled MCP/editor templates, validation assets, and traceability docs.
- Reason: make the starter's structure easier to understand before teams choose an adoption mode or enable optional workflow surfaces.
- Affected files: README.md, DOC-CHANGELOG.md
- Related code: None
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-06-06 - Document pre-push starter release status

- Area: release notes, repository governance, workflow asset status
- Change type: docs, release-notes
- Summary: documented the current pre-push state of the upgraded starter, including the validation readiness caveat and the known local `actions/checkout@v4` resolver diagnostics.
- Reason: preserve a clear release-status note before pushing the new version.
- Affected files: CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-06-06 - Record pre-push starter release status"
- Review status: reviewed
- Discrepancies or follow-up: final Bash and PowerShell starter validation passed after LF normalization; no documentation follow-up remains.

### 2026-06-06 - Upgrade starter workflow documentation and overlays

- Area: README, prompts, skills, agents, runbooks, memory strategy, runtime overlays, eval docs
- Change type: docs, runbook, onboarding, policy, reference
- Summary: added reusable prompt files, new workflow skills, security and documentation agents, memory strategy instructions and runbook, optional Hermes and Honcho overlays, tool-surface matrix, starter adoption guide, eval task/checklist docs, expanded MCP and hook runbooks, and rewrote the README around the 2026 repo-native workflow/governance positioning.
- Reason: evolve the starter from a VS Code/Copilot-oriented baseline into a production-grade cross-agent workflow starter while keeping optional runtime and memory integrations disabled by default.
- Affected files: README.md, .github/prompts/*.prompt.md, .github/skills/*/SKILL.md, .github/agents/*.agent.md, .github/instructions/*memory*.md, .github/instructions/hermes-runtime.instructions.md, docs/runbooks/*.md, .github/examples/**/*.md, evals/**/*.md
- Related code: CHANGELOG.md entry "2026-06-06 - Add production-grade starter validation and CI"
- Review status: reviewed
- Discrepancies or follow-up: local workflow diagnostics could not resolve `actions/checkout@v4`, which appears to be an external-action resolver limitation rather than a YAML syntax issue

### 2026-03-16 - Add existing-project rollout order to README

- Area: onboarding and adaptation guidance
- Change type: docs
- Summary: added an explicit phased rollout order for existing repositories: minimal merge, validation, then incremental module additions.
- Reason: make the adoption sequence explicit in the primary entrypoint doc and align with the runbook guidance.
- Affected files: README.md
- Related code: None
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-03-16 - Add required optional sample-only checklist table

- Area: migration runbook
- Change type: runbook
- Summary: added an artifact checklist table that classifies starter assets as required, optional, or sample-only and defines what to do when each artifact is missing in a target repo.
- Reason: make existing-repo adoption consistent even when `.github` structures differ from the sample project.
- Affected files: docs/runbooks/adopting-existing-github.md
- Related code: None
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-03-16 - Clarify sample file lists are illustrative

- Area: migration runbooks
- Change type: docs
- Summary: clarified that sample project-doc paths are examples only and that real adoption should map by purpose instead of exact filename.
- Reason: prevent incorrect assumptions when target repositories have different `.github` structures or missing sample-equivalent files.
- Affected files: docs/runbooks/adopting-existing-github.md, docs/runbooks/starter-composition.md
- Related code: None
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-03-16 - Add existing-.github adoption runbook and wiring

- Area: starter runbooks and README
- Change type: runbook
- Summary: added a dedicated migration runbook for repositories that already contain `.github` assets, and linked it from the composition runbook and README adaptation sections.
- Reason: provide concrete, low-risk merge guidance that prevents accidental overwrite of existing project-specific `.github` files.
- Affected files: docs/runbooks/adopting-existing-github.md, docs/runbooks/starter-composition.md, README.md
- Related code: CHANGELOG.md entry "2026-03-16 - Add existing-.github adoption runbook to governance manifest"
- Review status: reviewed
- Discrepancies or follow-up: none

### 2026-03-09 - Initialize documentation changelog

- Area: repository governance
- Change type: docs
- Summary: added a dedicated documentation changelog for tracking Markdown and text updates separately from source changes.
- Reason: make doc updates traceable and easier to cross-reference against implementation changes.
- Affected files: DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-03-09 - Initialize source code changelog"
- Review status: reviewed
- Discrepancies or follow-up: none
