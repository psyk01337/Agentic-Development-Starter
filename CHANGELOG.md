# Source Code Changelog

Use this log for changes to source code, scripts, infrastructure-as-code, build logic, configuration that affects runtime behavior, and other executable assets regardless of platform, language, or framework.

## How To Use

1. Add a new entry whenever a change affects behavior, interfaces, validation, runtime configuration, automation, or test logic.
2. Cross-reference the related documentation update in `DOC-CHANGELOG.md` when behavior, setup, contracts, or usage changed.
3. If no documentation update was needed, say so explicitly in the entry.
4. Record discrepancies, follow-up work, or known gaps so later reviews can trace why code and docs may differ.

## Entry Template

### YYYY-MM-DD - Short change title

- Area: subsystem, package, service, app, script, or repo path
- Change type: feature, fix, refactor, security, test, build, config, migration, chore
- Summary: what changed in the codebase
- Reason: why the change was needed
- Affected files: relevant paths
- Related docs: matching `DOC-CHANGELOG.md` entry, docs path, or `None`
- Validation: tests, lint, manual checks, or `Not run`
- Discrepancies or follow-up: known gaps, deferred work, or `None`

## Entries

### 2026-09-12 - Announce skipped fixtures, correct the index wording, and accept ADR 0003

- Area: supervisor orchestration validators, overlay runbook, overlay ADR, governance approval record
- Change type: fix, test, docs, chore
- Summary: a run with `SUPERVISOR_SKIP_FIXTURES=1` now reports the bypass on both platforms instead of returning success silently. The Bash twin prints `[NOTICE] SUPERVISOR_SKIP_FIXTURES=1 is set: the fixture suite was skipped, so this run asserted only the static checks.` to stderr; the PowerShell twin emits the same sentence through `Write-Warning`. This closes SEC-1. Corrected the over-generalised "non-zero index" rationale in `docs/runbooks/supervisor-orchestration.md` and the matching `DOC-CHANGELOG.md` entry so both are scoped the way the code comment already was: the entry-absent state is observed at the last member's index, which is non-zero for any tier larger than one and index 0 for a single-member tier, while the dropped-removal self-check still fires at every legal tier size. This closes NB-1. Accepted ADR 0003 (`Status: Proposed` -> `Accepted`), added a `- Approved:` line recording the 2026-09-12 maintainer approval for the `core-governance-change`, and refreshed the ADR's implementation-status line from the stale 2026-09-11 execution to the 2026-09-12 validation and review state.
- Reason: QA returned PASS with no blocking defects and two worthwhile non-blocking items, SEC-1 and NB-1. A `core-governance-change` requires recorded maintainer approval before merge, and ADR 0003 was still `Proposed` with an implementation-status line that predated the 2026-09-12 validator edits.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-12 - Record the SEC-1 skip notice, the corrected index wording, and ADR 0003 acceptance"
- Validation: `bash .github/scripts/check-supervisor-orchestration.sh` and `pwsh -NoProfile -File .github/scripts/check-supervisor-orchestration.ps1` both passed after the edits. The SEC-1 notice was observed directly on both platforms with `SUPERVISOR_SKIP_FIXTURES=1`, each exiting 0, and each skipped run still reported `Supervisor orchestration overlay check passed.`, so the notice is additive rather than a failure. Because a non-skipped run re-enters the validator with the variable set for every fixture, the new notice also had to leave the fixture substring expectations intact: `bash .github/scripts/check-starter-workflow.sh` passed all ten checks in 29s and `pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1` passed the same ten, with the supervisor check at 20s in the Bash run. `bash .github/scripts/check-markdown-quality.sh` passed after the wording edits.
- Discrepancies or follow-up: the non-blocking findings not selected for this slice remain open and unchanged. NB-2: the frontmatter-authoritative derivation is still not pinned, because the positive fixture only proves acceptance of an agent with no matrix entry. NB-3: the pre-existing half-normalised PowerShell parity pairs (`-notcontains` frontmatter/matrix comparison, schema-enum drift, and the untrimmed unbounded-indicator check) remain deliberately deferred. SEC-2: `.github/hooks/logs` is still not gitignored, and its remediation touches an approval-protected policy file, so it belongs to the governance owner. SEC-3 and SEC-4 remain informational. The `orchestration-coordinator` agent-registration escalation and the `evals/tasks/problem-structuring.md` manifest gap are still open.

### 2026-09-12 - Make the tier fixture's guarantee unconditional and pin the tolerated entry-absent state

- Area: supervisor orchestration validators, overlay runbook, overlay ADR
- Change type: fix, test, docs
- Summary: the `empty-non-mutating-tier` fixture no longer gates its anti-vacuity machinery on the tier's size. It pre-removes the last derived member's `agentCapabilityMatrix` entry (`matrix.pop(non_mutating[-1][0], None)` in the Bash twin, `$matrix.PSObject.Properties.Remove($nonMutating[-1].Name)` in the PowerShell twin) instead of the second member's, and both the pre-removal and the missing-entry self-check are now unconditional for any non-empty tier. The old guard read `len(non_mutating) > 1`, so a governance edit that reduced the tier to one member — a legal state the validator's own non-emptiness check permits — silently deleted both the pop and the check and returned the fixture to the unexercised state the previous entry removed, with nothing going red. The `elif index == 0` first-member deletion was dropped rather than documented: removing it leaves the fixture passing unchanged, so it pinned nothing while `CHANGELOG.md` and the runbook described it as one of two exercised paths. Both harnesses gained a `run_positive_fixture` / `Test-PositiveFixture` counterpart to the negative runner and a shared tier-derivation helper (`derive_non_mutating_tier` / `Get-FixtureNonMutatingTier`) so the two fixtures cannot derive the tier differently. The new positive fixture, `allow-listed-agent-without-matrix-entry`, removes one allow-listed non-mutating member's `agentCapabilityMatrix` entry and requires the validator to accept the result. Because the validators now assert two properties of the tier definition instead of one, the ADR and runbook sentences that claimed "one property" were rewritten, and the tolerance is pinned by paired text assertions on the new phrase `requires the validator to accept the result` in both documents, both platforms.
- Reason: independent code review of the entry above returned `needs-revision`. W1: the guarantee was conditional on `len(non_mutating) > 1` while `CHANGELOG.md` and the runbook stated it unconditionally. W2: the tolerated state was exercised only as a side effect of the tier fixture and no fixture asserted that the validator accepts it, so a later hardening that rejected it would have broken a documented contract with the suite still green. S1: only the entry-absent half of the two claimed paths was pinned.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-12 - Record the tolerated-state fixture and scope the tier fixture's claimed coverage"
- Validation: `bash .github/scripts/check-supervisor-orchestration.sh` and `pwsh -NoProfile -File .github/scripts/check-supervisor-orchestration.ps1` both passed with seventeen negative fixtures, one positive fixture, and the baseline. Ten probes on throwaway copies, five per platform, with matching results on both twins. To drop the pre-removal without breaking the Python heredoc, the pop call is replaced with `pass` rather than deleted. On the shipped tree with the pre-removal dropped, both twins exit 1 with `the mutation loop never observed an allow-listed tier member without an agentCapabilityMatrix entry, so the missing-entry path is unexercised`. On a tree whose tier is reduced to one member by making `architecture-reviewer` and `code-reviewer` mutating in both frontmatter and matrix, both twins exit 0, which is the tier size the old guard skipped. With the pre-removal also dropped on that one-member tree, both twins exit 1 with the same self-check message, so the check is live at the boundary size. With the old `len(non_mutating) > 1` condition reconstructed on that same one-member tree (both guard conditions re-applied and verified by grep), both twins exit 0, which reproduces the silent gap the change closes. For the new fixture, hardening each twin on a copy to reject an allow-listed agent with no `agentCapabilityMatrix` entry makes both exit 1 with `Positive fixture rejected an accepted state: an allow-listed non-mutating agent file has no agentCapabilityMatrix entry`, so the positive fixture is proven non-inert rather than assumed. For the new text assertions, replacing the pinned phrase in the ADR on a copy of the tree makes both twins exit 1 with `Missing expected content for tolerated-state positive fixture note in the ADR in docs/adr/0003-supervisor-orchestration-overlay.md`, so the pin is load-bearing. `bash .github/scripts/check-starter-workflow.sh` passed all ten checks in 28s and `pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1` passed the same ten. No probe directory, `sov-fixture-*` directory, or tamper copy was left behind, and the two throwaway probe scripts were deleted.
- Discrepancies or follow-up: the assertions still prove only how the tier is defined and derived, never that it was used, and the tier fixture still creates the tolerated state artificially rather than observing one. The pre-existing case-insensitive frontmatter/matrix comparison in the PowerShell twin (`$matrixTools -notcontains $_`) is unchanged and remains a half-normalised parity pair. A run with `SUPERVISOR_SKIP_FIXTURES=1` still reports success with every fixture skipped and no notice. The tier-member names, the eighteen-fixture count, and the positive fixture's description in `docs/runbooks/supervisor-orchestration.md` remain unpinned enumerations, so that silent-drift class still applies to them. ADR 0003's implementation-status line still records execution on 2026-09-11 and does not reflect the 09-12 validator edits. ADR 0003 remains `Proposed`.

### 2026-09-12 - Cover the fixture's entry-absent branch and sort the PowerShell fixture enumeration

- Area: supervisor orchestration validators, architecture doc validation list
- Change type: fix, test, docs
- Summary: the `empty-non-mutating-tier` fixture now reaches the branch it exists to guard. It removed the first derived member's `agentCapabilityMatrix` entry from inside the mutation loop, which happens after that member's own lookup, so every later iteration still resolved an entry and the guard's entry-absent branch was never taken; the previous entry's claim that the fixture "exercises the guarded path" held only for the deletion half. The fixture now also removes a second member's entry before the loop starts, so a non-zero index does reach that state, and it reports a fixture error when the mutation loop never observes a member without an entry, which turns a dropped pre-removal into a loud failure instead of a silent return to an unexercised branch. The PowerShell twin now enumerates agent files with `Sort-Object Name` in the fixture derivation, matching the sorted glob the Bash twin uses and the sorted enumeration the validator body already used, so both platforms mutate the same member. Added `check-supervisor-orchestration.sh` to the validation list in `docs/ARCHITECTURE.md`, which had enumerated nine of the ten checks the paired workflow entry points run.
- Reason: independent code review of the entry above returned `needs-revision`. Finding 1 (blocker): reverting the guard left all seventeen fixtures green because the fixture never created the state the guard handles, and both the author and the QA pass had to hand-edit a copy of `tool-access.json` to demonstrate the fix. Finding 2: the PowerShell fixture's "first member" depended on filesystem enumeration order and its precondition was unasserted. Finding 3: `docs/ARCHITECTURE.md` understated the validation pipeline.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, docs/ARCHITECTURE.md, docs/runbooks/supervisor-orchestration.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-12 - Record the third validator in the architecture validation list"
- Validation: `bash .github/scripts/check-starter-workflow.sh` passed all ten checks in 27s and `pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1` passed the same ten. Three probes on throwaway copies of the repository: with the guard reverted and the pre-removal kept, the fixture fails and the validator exits 1 with `[ERROR] Negative fixture could not be applied: every allow-listed agent gains a mutating capability, emptying the non-mutating tier` and `AttributeError: 'NoneType' object has no attribute 'setdefault'`; with the pre-removal removed and the guard kept, the validator exits 1 with `[ERROR] Negative fixture could not be applied: the mutation loop never observed an allow-listed tier member without an agentCapabilityMatrix entry, so the missing-entry path is unexercised`; with both reverted to the pre-fix state the validator still exits 0, which reproduces the reported coverage gap. The same guard-reverted probe on the PowerShell twin exits 1 with `Negative fixture could not be applied: every allow-listed agent gains a mutating capability, emptying the non-mutating tier (Cannot index into a null array.)`, so both platforms fail the fixture rather than passing it. No probe directory or `sov-fixture-*` directory was left behind, and `.tmp-verify` does not exist.
- Discrepancies or follow-up: findings 4, 5, and 6 from the review are recorded rather than closed. The tier-member names and the seventeen-fixture count stated in `docs/runbooks/supervisor-orchestration.md` and `docs/adr/0003-supervisor-orchestration-overlay.md` remain accurate but unpinned, so that silent-drift class still applies to those enumerations. The pre-existing case-insensitive frontmatter/matrix comparison in the PowerShell twin (`$matrixTools -notcontains $_`) is unchanged and remains a half-normalised parity pair. A run with `SUPERVISOR_SKIP_FIXTURES=1` still reports success with every fixture skipped and no notice. No fixture deliberately fails setup, so the fixture harness's unappliable-fixture path is reachable only through the revert probes above. ADR 0003 remains `Proposed`.

### 2026-09-12 - Harden the non-mutating tier fixture and pin the tier's frontmatter derivation

- Area: supervisor orchestration validators, overlay ADR and runbook assertions
- Change type: fix, test
- Summary: the `empty-non-mutating-tier` fixture no longer assumes that every allow-listed non-mutating agent has an `agentCapabilityMatrix` entry. An allow-listed agent file with no matrix entry is a state the validator body accepts and the runbook documents as deliberate, and the previous unguarded `access["agentCapabilityMatrix"][agent_name]["tools"]["edit"] = True` (Bash) and `$access.agentCapabilityMatrix.$agentName.tools | Add-Member` (PowerShell) aborted the whole validator on that state instead of reporting a fixture diagnostic. The fixture now deletes the first member's matrix entry on purpose, which exercises the guarded path and proves the tier is derived from the authoritative frontmatter scan rather than from the matrix. Both harnesses now treat a fixture setup or mutation failure as an explicit reported error and remove the fixture copy on that path. The PowerShell tier predicate and the PowerShell fixture derivation now use the case-sensitive `-cnotcontains` operators, matching the case-sensitive set membership the Bash twin uses, so a case-divergent `tools` list can no longer classify as non-mutating on one platform and mutating on the other. Both platforms now assert the runbook and ADR sentence that states the derived tier is non-empty. Corrected the fixture comments that claimed the frontmatter/matrix agreement check would fire instead of the tier check. Corrected the ADR and runbook sentence that described the tier as derived from `agentCapabilityMatrix`; it is derived from each agent's `tools` frontmatter, which the validators cross-check against the matrix.
- Reason: code review of the entry below returned `needs-revision`. W2 - the fixture aborted on a repository state the runbook explicitly permits, which skipped every remaining fixture and leaked its temporary copy. W1 - the two shipped design statements contradicted the code path this entry's predecessor added. S1 - divergent case semantics between the paired validators in the new predicate. S2 - the new documentation claim had no assertion pinning it, unlike the neighbouring `preToolUse` claim. S3 - the fixture comment overstated the control flow.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, docs/adr/0003-supervisor-orchestration-overlay.md, docs/runbooks/supervisor-orchestration.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-12 - Correct the non-mutating tier's derivation source and pin the claim"
- Validation: `bash .github/scripts/check-supervisor-orchestration.sh` and `pwsh -NoProfile -File .github/scripts/check-supervisor-orchestration.ps1` both passed with seventeen negative fixtures plus the baseline. Reachability probe on a throwaway copy with `agentCapabilityMatrix["code-reviewer"]` removed: a guard-removed copy of the validator fails with `TypeError: 'NoneType' object is not subscriptable` raised from the fixture, while the fixed validator passes that same tree with exit code 0 and no traceback, and the failing run leaves no fixture directory behind because the new failure path removes the copy. `bash .github/scripts/check-starter-workflow.sh` passed all ten checks in 26s and `pwsh -NoProfile -File .github/scripts/check-starter-workflow.ps1` passed the same ten.
- Discrepancies or follow-up: the assertion still proves only that the tier is defined, never that it was used. The repository state this fixture now tolerates is exercised as a side effect of that fixture rather than by a fixture of its own. The pre-existing case-insensitive frontmatter/matrix comparison in the PowerShell twin (`$matrixTools -notcontains $_`) is unchanged and remains a parity gap of the same class as S1, deliberately left out of this slice. ADR 0003 remains `Proposed` pending maintainer acceptance.

### 2026-09-11 - Assert the non-mutating delegation tier is non-empty

- Area: supervisor orchestration validators
- Change type: test, fix
- Summary: both paired validators now derive the non-mutating delegation tier from the authoritative agent-frontmatter scan — allow-listed agents whose declared capabilities are a subset of `read`, `search`, and `todo` — and fail when that tier is empty. Added an `empty-non-mutating-tier` negative fixture per platform that derives the tier the same way the validator does and then gives every member `edit` in both its `tools` frontmatter and its `agentCapabilityMatrix` entry, so the mutation exercises the tier branch instead of the frontmatter/matrix agreement branch.
- Reason: the enablement precondition recorded in ADR 0003 and the overlay runbook is capability-scoped: an unverified hook-inheritance result withholds mutating delegation rather than blocking enablement. Nothing asserted that a non-mutating tier still existed to withhold delegation to, so an edit that gave every allow-listed agent a mutating capability would have silently turned the capability-scoped rule into the total block the ADR rejects, with every existing check still green.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1
- Related docs: DOC-CHANGELOG.md entry "2026-09-11 - Document the non-empty non-mutating tier assertion"
- Validation: `bash .github/scripts/check-supervisor-orchestration.sh` and `pwsh -NoProfile -File .github/scripts/check-supervisor-orchestration.ps1` both passed with seventeen negative fixtures each plus a baseline fixture, so the new branch is proven non-inert rather than assumed. Independent probes confirmed reachability and cross-platform parity: emptying the tier in a temporary copy produced `specialist allow-list has no non-mutating tier: no allow-listed agent declares capabilities within read, search, todo, so an unverified hook-inheritance result would withhold delegation entirely instead of scoping it` from both validators, byte-identical. `bash .github/scripts/check-starter-workflow.sh` passed all ten checks in 28s and `.github/scripts/check-starter-workflow.ps1` passed the same ten, so the added assertions and the documentation edits are green on both entry points.
- Discrepancies or follow-up: the assertion can only prove the tier is defined, never that it was used, and it says nothing about whether hook inheritance holds in a target runtime; no static check can observe that, which is why it stays an enablement obligation. ADR 0003 remains `Proposed` pending maintainer acceptance. The `orchestration-coordinator` agent-registration escalation and the pre-existing `problem-structuring.md` eval-manifest gap both remain open.

### 2026-09-11 - Scope the supervisor frontmatter obligation and widen the enforcement-framing guard

- Area: supervisor orchestration validators, `delegation-supervisor` agent surface, `tool-access.json` role source of truth, overlay runbook
- Change type: fix, test, docs
- Summary: removed the last enforcement claims from shipped governance text. The `delegation-supervisor` agent description, its operating instruction, and the `orchestration` role `intent` in `.github/roles/tool-access.json` all stated that the supervisor "enforces the high-risk approval boundary", which contradicts `orchestration-policy.json:100` ("Documentation must not describe this gate as enforced authorization") and the same agent file's own constraint that the gate is not enforced authorization. All three now say the supervisor stops at the boundary and that the gate is a prompt-level contract, not a runtime control. Replaced the drift guard, which matched a single literal string in two files, with a line-level check over `.github/AGENTS.md`, `.github/roles/tool-access.json`, and every `.github/agents/*.agent.md` file that flags any line naming the boundary with an enforcement word unless the line also negates it. Scoped the `tools` frontmatter obligation to agents registered in `agentCapabilityMatrix` rather than every agent file, because `tools:` is optional in `.agent.md` frontmatter and this validator runs unconditionally from `check-starter-workflow`, so an adopter-authored agent without a `tools` list failed a check scoped to an overlay they had not enabled. Split the conflated diagnostics so a registered agent file that omits `tools` no longer reports as a missing file. Made the matrix/frontmatter comparison bidirectional by rejecting an enabled matrix tool that is absent from `toolDefinitions`, which could previously be dropped silently. Added an `agentRoleHints` agreement check against `agentCapabilityMatrix` roles. Normalised the tool-set diagnostics on both platforms to sorted comma-joined lists instead of a Python list repr on one side and comma-joined values on the other. Pruned `.github/hooks/logs` from the fixture copy. Added five negative fixtures per platform.
- Reason: a code review of the previous change confirmed its structural claims but rejected its coverage claim. The enforcement-framing defect the new guard was added to prevent was still shipped in three strings the guard could not see, one newly added branch had no fixture, the added agreement check was one-sided over the tool vocabulary, and the frontmatter requirement had silently become a repo-wide obligation for any adopter. Reviewer findings F1, F2, F3, F4, F5, F6, F7, and F8.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, .github/agents/delegation-supervisor.agent.md, .github/roles/tool-access.json, docs/runbooks/supervisor-orchestration.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-11 - Document the scoped frontmatter obligation and the widened approval-gate wording guard"
- Validation: `bash .github/scripts/check-supervisor-orchestration.sh` and `pwsh -NoProfile -File .github/scripts/check-supervisor-orchestration.ps1` both passed with sixteen negative fixtures each plus a baseline fixture. The two new branches added here, plus the three pre-existing branches that had no fixture, were each confirmed non-inert. A direct two-mutation probe confirmed identical diagnostics on both platforms: `qa frontmatter tools do not match agentCapabilityMatrix tools: frontmatter read, search, todo, matrix execute, read, search, todo` and `.github/agents/delegation-supervisor.agent.md:81 must not describe the supervisor approval gate as enforcement`. `bash .github/scripts/check-markdown-quality.sh`, `bash .github/scripts/check-agent-contracts.sh`, `bash .github/scripts/check-hook-policy.sh`, and `bash .github/scripts/check-starter-workflow.sh` were run.
- Discrepancies or follow-up: the guard still does not cover `docs/runbooks/supervisor-orchestration.md`, which describes the gate as non-enforced in prose and would false-positive, and it does not yet have a fixture proving the role-intent reach in `tool-access.json` (the agent-file reach is covered). `orchestration-coordinator` remains absent from `agentCapabilityMatrix` and `agentRoleHints`, and the runbook's stated reason for that boundary is inaccurate and is escalated to `architecture-reviewer` rather than reworded here: its `tools: [read, search, todo]` is exactly the `review` role's tool set, so registering it as `review` would pass every current check and the real blocker is semantic role fit. Whether `delegate-agent` is valid in `.agent.md` `tools` frontmatter remains an unverified platform contract question, also escalated. ADR 0003 remains `Proposed`. No independent `code-reviewer`, `security-reviewer`, or `qa` pass has been executed.

### 2026-09-11 - Close the supervisor sole-holder coverage gap and add delegation enablement preconditions

- Area: supervisor orchestration validators, overlay runbook, ADR 0003, delegation-plan schema
- Change type: fix, test, docs
- Summary: anchored the sole-holder invariant on every `.github/agents/*.agent.md` frontmatter instead of only the `roles` map, the `agentCapabilityMatrix`, and the `delegation-supervisor` file. Both paired validators now parse each agent file's `tools` list, require that exactly one agent declares `delegate-agent`, require the capability matrix to agree with every agent's frontmatter in both directions, reject a matrix entry that has no agent file, and reject a `specialistAllowList` that admits a delegation-capable agent. Added four negative fixtures to each validator: a worker frontmatter gaining `delegate-agent`, an agent file declaring `delegate-agent` while carrying no matrix entry, an allow-list admitting a delegation-capable agent, and an agent whose frontmatter diverges from its matrix entry. Stated hook inheritance for delegated subagents as an enablement precondition in ADR 0003 and in the runbook's new Enablement Preconditions and Supported Runtimes sections, added it to the ADR's required validation activities, and added validator assertions for that text. Recorded the `serializedReason` v1 optionality in `delegation-plan.schema.json` and the fixture harness's temporary audit-log copy in the runbook. Corrected the runbook paragraph that still claimed the check does not scan every agent file's frontmatter.
- Reason: M2 and L2 from the architecture review, both of which the previous entry recorded as open follow-ups. The sole-holder invariant held, but three named failure modes would have passed validation: a worker's frontmatter gaining `delegate-agent`, an agent file escaping the matrix entirely, and the allow-list admitting a delegation-capable agent. Hook inheritance was an undefined enablement obligation even though ADR 0003 already required a security review of the delegation boundary, and `preToolUse` is the only mechanical guardrail in the starter.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md, .github/schema/delegation-plan.schema.json
- Related docs: DOC-CHANGELOG.md entry "2026-09-11 - Document supervisor delegation-boundary coverage and enablement preconditions"
- Validation: `bash .github/scripts/check-supervisor-orchestration.sh` and `pwsh -NoProfile -File .github/scripts/check-supervisor-orchestration.ps1` both passed with eleven negative fixtures each, so every new branch is proven non-inert rather than assumed. The harness caught a real parity defect during this change: the Bash and PowerShell mismatch messages placed their interpolated tool lists differently, so the shared fixture expectation matched on PowerShell only. `bash .github/scripts/check-markdown-quality.sh` passed.
- Discrepancies or follow-up: `orchestration-coordinator` is still absent from `agentCapabilityMatrix` and `agentRoleHints`, and its catalog role label matches no core role id, so a blanket "every agent file must be registered in the matrix" rule would require a role-model decision. Delegation-capability completeness is enforced; general agent registration is not, and the runbook now records that boundary. ADR 0003 remains `Proposed` pending maintainer acceptance. No independent `code-reviewer`, `security-reviewer`, or `qa` pass has been executed.

### 2026-09-11 - Correct the supervisor approval-gate framing and close two validation gaps

- Area: starter governance text, supervisor orchestration validators, delegation-plan schema, overlay documentation
- Change type: fix, docs, test
- Summary: removed the "high-risk approval enforcement" claim from the `delegation-supervisor` row in `.github/AGENTS.md` and from the `delegation-supervisor` scope in `.github/roles/tool-access.json`, both of which described the prompt-level gate as enforcement. Added the prompt-level statement and a pointer to `docs/runbooks/supervisor-orchestration.md` to the supervisor's agent-catalog entry and to the orchestration pointer line, so the caveat is reachable from the file that made the claim. Added a regression guard to both paired validators that requires `prompt-level contract` and `supervisor-orchestration.md` in `AGENTS.md` and rejects `high-risk approval enforcement` in either `AGENTS.md` or `tool-access.json`, plus an `enforcement-overclaim` fixture that reintroduces the claim and requires rejection. Added `minLength: 1` to `writeSet.items` in `delegation-plan.schema.json` and a policy-driven check to both validators that rejects a declared write-set entry equal to any `writeSet.unboundedIndicators` value from the canonical policy, plus an `unbounded-write-set` fixture declaring `["TBD"]`. Corrected the `second-delegation-owner` fixture description, which overstated the path it exercises: it mutates a capability-matrix entry, not an agent file's frontmatter.
- Reason: a code review found that the shipped agent catalog described the approval gate as enforcement while `.github/roles/orchestration-policy.json`, ADR 0003, and the overlay runbook expressly forbid that framing; that the caveat was unreachable from the file making the claim; and that the write-set rule could not express its own serialize-when-unbounded trigger, so the artifact meant to make the rule reviewable could not represent it.
- Affected files: .github/AGENTS.md, .github/roles/tool-access.json, .github/schema/delegation-plan.schema.json, .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, docs/runbooks/supervisor-orchestration.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-11 - Correct supervisor approval-gate documentation framing"
- Validation: `bash .github/scripts/check-supervisor-orchestration.sh` and `pwsh -NoProfile -File .github/scripts/check-supervisor-orchestration.ps1` both passed; each now runs seven negative fixtures, and a fixture that fails to detect its mutation reports an error, so the new guards are proven non-inert rather than assumed. `bash .github/scripts/check-starter-workflow.sh` passed all ten checks in 18s, and `.github/scripts/check-starter-workflow.ps1` passed the same ten with exit 0. Markdown quality passed, so the edited documentation has no trailing whitespace or broken local links.
- Discrepancies or follow-up: ADR 0003 remains `Proposed` and still needs maintainer acceptance. The sole-holder invariant is still validated against the `roles` map and `agentCapabilityMatrix` rather than every agent file's frontmatter, and hook inheritance for delegated workers remains unverified; both were routed to `architecture-reviewer` as contract decisions rather than changed here. `serializedReason` stays optional and the embedded validator subset cannot express a negative constraint, so boundedness is machine-checked only for literal `unboundedIndicators` values; broader boundedness stays a review judgment. No independent `code-reviewer`, `security-reviewer`, or `qa` pass has been executed.

### 2026-09-11 - Remediate supervisor orchestration validator gaps

- Area: starter validation scripts, delegation-plan schema, overlay documentation
- Change type: fix, test, docs
- Summary: closed the validation gaps a code review found in the `overlay-supervisor-orchestration` module and fixed its failing gate. Pinned both paired validators to case-sensitive matching (`check-supervisor-orchestration.sh` used case-sensitive `grep -Eq` while `check-supervisor-orchestration.ps1` used the case-insensitive `-notmatch`) and corrected the `prompt-level` pattern to the real heading text `Prompt-level contract, not enforcement`, which was the cause of the red gate. Removed the success line the embedded Python printed before the text assertions ran, so a failing run no longer emits a passing message. Made `check-starter-workflow.sh` accumulate failures like its PowerShell twin instead of aborting on the first one, which previously masked five downstream checks. Added the JSON Schema draft 2020-12 subset evaluator both validators use to check `.github/examples/supervisor-orchestration/complex-feature-delegation-plan.json` against `delegation-plan.schema.json`, plus a drift check between the schema's agent enum and the canonical policy allow-list. Added assertions for the previously unchecked policy fields `delegationDepth.workersMayDelegate`, `enforcement.runtimeEnforced`, `writeSet.requiredBeforeWriteDelegation`, `fallbackWhenDelegationUnavailable.silentDegradationAllowed`, and `deferredProposal.status`. Added negative fixtures to both validators: each copies the repository state, mutates one fact, and requires the validator to reject it with a specific message, covering the overlay being enabled by default, a second agent or role holding `delegate-agent`, supervisor frontmatter diverging from the `orchestration` role, and a write delegation that omits its declared write set. Required `writeSet` for `capability: "write"` delegations in `delegation-plan.schema.json` via `if`/`then`, so the artifact that exists to make the write-set rule reviewable can no longer permit a write delegation with no write set.
- Reason: the module's own Bash gate was red on `main`, and CI runs it, so the `validate` job was failing. The delegation boundary had no behavioral coverage, every control was verified only as repository text, and the schema did not encode the write-set rule the ADR and the canonical policy both state. The paired validators also implemented "file contains pattern" with divergent case semantics, which is the defect class the new fixtures guard.
- Affected files: .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, .github/scripts/check-starter-workflow.sh, .github/schema/delegation-plan.schema.json, docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-11 - Document supervisor orchestration validation coverage"
- Validation: `bash .github/scripts/check-starter-workflow.sh` passed all ten checks (manifest, skills, agent contracts, approval-gated orchestration, supervisor orchestration, hook policy, prompt contracts, MCP posture, Markdown quality, eval harness); `.github/scripts/check-starter-workflow.ps1` passed with the same ten checks. Each fixture re-runs the validator against a mutated copy of `.github` and `docs` and asserts both a non-zero exit and the expected error message, so the fixtures fail loudly if a branch degrades into a no-op; a baseline run asserts the unmutated copy passes. `check-starter-workflow.sh` was also run against a deliberately broken copy and executed all ten checks while reporting six failures, confirming that one failure no longer aborts the run and masks the rest.
- Discrepancies or follow-up: ADR 0003 remains `Proposed` pending maintainer acceptance because the change touches two core modules. No `security-reviewer`, `code-reviewer`, or `qa` pass has been executed, and an independent pass is still required before any repo enables the overlay. The approval gate and the write-set rule remain prompt-level contracts rather than enforced controls, and the validators implement only the JSON Schema subset this schema uses; the runbook documents the full external validator command. The prior entry's "static verification only" limitation is discharged by this entry, which leaves it intact as a record of that session.

### 2026-09-11 - Implement supervisor orchestration overlay

- Area: starter agents, roles, skills, guardrails, validators, manifest, runbooks, architecture docs
- Change type: feature
- Summary: implemented the default-disabled `overlay-supervisor-orchestration` module. Added the `delegation-supervisor` agent with `read`, `search`, `todo`, and `delegate-agent` only; added the `delegate-agent` capability and the `orchestration` role to `.github/roles/tool-access.json` (version 1.1 to 1.2) with the matching capability-matrix entry and role hint; added `.github/roles/orchestration-policy.json` as the canonical machine-readable source for approval categories, routing criteria, delegation depth, the specialist allow-list, and the write-set rule; added the `supervisor-orchestration` skill, the `supervisor-orchestration` runbook, a delegation-plan schema, and a worked example; added paired validators `check-supervisor-orchestration.sh` and `.ps1` and registered them in both workflow entry points; added `delegation-supervisor` to both agent-contract validators; registered the module in `.github/starter-modules.json` (version 1.6 to 1.7); updated `AGENTS.md`, `agentic-dev.md`, `starter-composition.md`, `INDEX.md`, `MIGRATION.md`, `tool-surface-matrix.md`, `ARCHITECTURE.md`, `hooks/agent-policy.json`, and `README.md`; updated ADR 0003 to record the settled naming, canonical policy source, routing criteria, and allow-list.
- Reason: implement the reviewed and user-approved supervisor orchestration overlay as a default-disabled optional module without changing core guided-handoff behavior.
- Affected files: .github/agents/delegation-supervisor.agent.md, .github/skills/supervisor-orchestration/SKILL.md, .github/roles/orchestration-policy.json, .github/roles/tool-access.json, .github/schema/delegation-plan.schema.json, .github/examples/supervisor-orchestration/complex-feature-delegation-plan.json, .github/scripts/check-supervisor-orchestration.sh, .github/scripts/check-supervisor-orchestration.ps1, .github/scripts/check-starter-workflow.sh, .github/scripts/check-starter-workflow.ps1, .github/scripts/check-agent-contracts.sh, .github/scripts/check-agent-contracts.ps1, .github/starter-modules.json, .github/AGENTS.md, .github/hooks/agent-policy.json, docs/runbooks/supervisor-orchestration.md, docs/runbooks/agentic-dev.md, docs/runbooks/starter-composition.md, docs/runbooks/INDEX.md, docs/runbooks/tool-surface-matrix.md, docs/ARCHITECTURE.md, docs/adr/0003-supervisor-orchestration-overlay.md, MIGRATION.md, README.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-11 - Document supervisor orchestration overlay implementation"
- Validation: static verification only. The paired Bash and PowerShell suites could not be executed because no terminal tool was available in this session; the new validator's assertions were checked by inspection against the repository state. Run `bash .github/scripts/check-starter-workflow.sh` and `.github/scripts/check-starter-workflow.ps1` before merging.
- Discrepancies or follow-up: ADR 0003 remains `Proposed` pending maintainer acceptance because the change adds entries to two core modules. No `security-reviewer`, `code-reviewer`, or `qa` pass was executed in this session, and those remain required before any repo enables the overlay. The approval gate and the write-set rule are prompt-level contracts, not enforced controls, and static validation cannot prove runtime isolation, write locking, or approval non-bypassability.

### 2026-09-10 - Add Phaser game development overlays, prompts, skill, evals, and guardrails

- Area: starter instructions, prompts, skills, evals, guardrails, manifest
- Change type: feature, security, enhancement
- Summary: added an engine-agnostic game overlay set (`gameplay-systems.instructions.md` covering simulation/presentation separation, fixed-timestep determinism, explicit state machines, data-driven tuning, and save versioning; `game-performance.instructions.md` covering frame budgets, measure-first discipline, per-frame allocation and pooling, draw calls, and loading; `game-assets-pipeline.instructions.md` covering the masters/runtime storage boundary, provenance and licensing, naming, and derived-asset determinism) plus a Phaser engine overlay (`phaser.instructions.md`) covering version and documentation discipline, precedence over React/Next.js inside `app/game/`, scene lifecycle, input, scaling, persistence, and the client-trust boundary; added four prompts (`design-game-system`, `implement-game-mechanic`, `profile-game-performance`, `prepare-game-build`); added the `game-perf-triage` skill; added two eval golden tasks with checklists (`gameplay-mechanic`, `game-perf-triage`) and registered them in both eval runners and both eval harness checks; added four hook policy rules blocking staging of app signing or provisioning material, signing or store credentials written to `.env`, `git lfs migrate` history rewrites, and forced `git lfs prune`, each with denied and allowed fixtures in both policy checkers; registered `overlay-game-core` and `overlay-game-phaser` in `.github/starter-modules.json` (version 1.5 to 1.6). All game overlays are path-scoped to `app/game/**` so they never attach to non-game TypeScript or JavaScript.
- Reason: the starter had no game development coverage; game adopters inherited language-generic overlays, a `.gitattributes` with no binary or large-file handling, no client-trust rules for browser games, and no guardrails against committing signing material or rewriting asset history.
- Affected files: .github/instructions/phaser.instructions.md, .github/instructions/gameplay-systems.instructions.md, .github/instructions/game-performance.instructions.md, .github/instructions/game-assets-pipeline.instructions.md, .github/prompts/design-game-system.prompt.md, .github/prompts/implement-game-mechanic.prompt.md, .github/prompts/profile-game-performance.prompt.md, .github/prompts/prepare-game-build.prompt.md, .github/skills/game-perf-triage/SKILL.md, evals/tasks/gameplay-mechanic.md, evals/tasks/game-perf-triage.md, evals/expected/gameplay-mechanic.checklist.md, evals/expected/game-perf-triage.checklist.md, evals/run-evals.sh, evals/run-evals.ps1, .github/scripts/check-evals.sh, .github/scripts/check-evals.ps1, .github/hooks/policy-rules.tsv, .github/scripts/check-hook-policy.sh, .github/scripts/check-hook-policy.ps1, .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-09-10 - Document Phaser game development overlays, runbook, and examples"
- Validation: `bash .github/scripts/check-starter-workflow.sh` passed all nine checks (manifest, skills, agent contracts, approval-gated orchestration, hook policy, prompt contracts, MCP posture, Markdown quality, eval harness); `.github/scripts/check-starter-workflow.ps1` passed with the same results.
- Discrepancies or follow-up: the asset storage policy for authoring masters is deliberately left repo-specific and is not enforced by any validator; the starter-wide default is now recorded as a `Proposed` ADR in `docs/adr/0002-game-asset-storage-policy.md` and needs maintainer acceptance before it is binding. Eval coverage for the asset overlay and the `prepare-game-build` prompt is deferred until a repo exercises them.

### 2026-09-04 - Scope runtime overlays and pin Copilot instruction setting

- Area: starter instructions, editor config
- Change type: fix, config
- Summary: changed `hermes-runtime.instructions.md` `applyTo` from `**/*` to `.hermes/**` and `honcho-memory.instructions.md` `applyTo` from `**/*` to `{honcho.*,.honcho/**}` so the optional runtime overlays are no longer force-injected into every Copilot prompt in adopting repositories; added `github.copilot.chat.codeGeneration.useInstructionFiles: true` to `.vscode/settings.json` so repo instruction files apply deterministically across contributors instead of depending on personal settings.
- Reason: the runtime overlays are marked default-disabled in the manifest but their `**/*` scope attached them to every file, contradicting the modular design and diluting prompt context; the setting pin removes silent per-user drift that can disable repo instructions.
- Affected files: .github/instructions/hermes-runtime.instructions.md, .github/instructions/honcho-memory.instructions.md, .vscode/settings.json
- Related docs: DOC-CHANGELOG.md entry "2026-09-04 - Document runtime overlay scoping"
- Validation: static review only; run `bash .github/scripts/check-starter-workflow.sh` and `.github/scripts/check-starter-workflow.ps1` before merging.
- Discrepancies or follow-up: none

### 2026-09-04 - Add technique guidance to frontend and backend overlays

- Area: starter instructions, frontend, backend
- Change type: enhancement
- Summary: expanded `.github/instructions/frontend.instructions.md` with new Data Fetching and Async (cancellation, stale-while-revalidate, bounded retries), Forms (boundary validation, accessible errors, input preservation), and Security (no untrusted HTML, URL sanitization, token storage) sections plus derived-state, code-splitting, and focus-management guidance; expanded `.github/instructions/backend.instructions.md` with new Concurrency and I/O and Security sections plus idempotency, pagination, structured error codes, N+1 avoidance, index discipline, migration reversibility, centralized error handling, and integration-test guidance.
- Reason: raise agent output quality on coding tasks with concrete best-practice technique rules in the two most-used stack overlays.
- Affected files: .github/instructions/frontend.instructions.md, .github/instructions/backend.instructions.md
- Related docs: DOC-CHANGELOG.md entry "2026-09-04 - Document frontend and backend technique guidance"
- Validation: static review only; run `bash .github/scripts/check-starter-workflow.sh` and `.github/scripts/check-starter-workflow.ps1` before merging.
- Discrepancies or follow-up: none

### 2026-09-04 - Harden hooks, prompt contracts, and add CI workflow overlay

- Area: starter guardrails, prompts, instructions, manifest
- Change type: feature, security, fix
- Summary: expanded `.github/hooks/policy-rules.tsv` with destructive git commands (`git clean -f`, `git checkout .`, `git restore .`, `git stash drop/clear`, `git branch -D`), Windows `rmdir /s /q`, Docker teardown/prune commands, staging of likely secret files, and broader credential-name writes to `.env`; added matching denied and allowed fixtures to `check-hook-policy.sh` and `check-hook-policy.ps1`; the `git branch -D` rule uses a scoped case-sensitive `(?-i:-D)` group and the PowerShell matcher no longer lowercases input so the safe `git branch -d` stays allowed; fixed prompt-contract drift by deriving the required prompt list from `starter-modules.json` (all 14 prompts are now validated) and widening the stop-rule check to accept any "stop and ask before" clause; added `fix-bug` and `add-policy-rule` prompts; added a new `overlay-ci` module with `.github/instructions/ci.instructions.md`; bumped manifest version 1.4 to 1.5.
- Reason: close guardrail blind spots for common coding-day hazards and fix validator drift that left two prompts unvalidated.
- Affected files: .github/hooks/policy-rules.tsv, .github/hooks/scripts/pre-tool-policy.ps1, .github/scripts/check-hook-policy.sh, .github/scripts/check-hook-policy.ps1, .github/scripts/check-prompt-contracts.sh, .github/scripts/check-prompt-contracts.ps1, .github/prompts/fix-bug.prompt.md, .github/prompts/add-policy-rule.prompt.md, .github/instructions/ci.instructions.md, .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-09-04 - Document guardrail, instruction, and prompt hardening"
- Validation: `bash .github/scripts/check-prompt-contracts.sh` passed; `bash .github/scripts/check-starter-workflow.sh` passed manifest, skills, agent-contracts, and approval-gated checks before stopping at the hook policy fixture; the `git branch -D` rule was corrected to the scoped `(?-i:-D)` pattern and `bash .github/scripts/check-hook-policy.sh` now passes — re-run both umbrella scripts (`check-starter-workflow.sh` and `.ps1`) before merging.
- Discrepancies or follow-up: `docs/ARCHITECTURE.md` was missing the `overlay-static-prototype` node; added it as part of this change.

### 2026-08-18 - Fix stale CI workflow registrations in the module manifest

- Area: starter governance, manifest, CI
- Change type: fix, config
- Summary: corrected `core-ci-validation` in `.github/starter-modules.json` to reference the workflow files that actually exist — `.github/workflows/validation.yml` and `.github/workflows/skill-contract-tests.yml` — replacing three stale entries (`starter-validation.yml`, `markdown-quality.yml`, `hook-policy-tests.yml`) left over from the workflow consolidation; manifest version 1.3 to 1.4.
- Reason: `bash .github/scripts/check-starter-workflow.sh` failed with "Manifest-listed file does not exist" for the three workflow files that no longer exist.
- Affected files: .github/starter-modules.json
- Related docs: None
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-08-18 - Add Laravel component eval golden task and checklist

- Area: starter workflow, evals, manifest
- Change type: enhancement
- Summary: added `evals/tasks/laravel-component.md` and `evals/expected/laravel-component.checklist.md` to exercise the PHP/Laravel stack overlays (Livewire component change honoring the PHP, Laravel, Livewire, Alpine, and database overlays); registered both files in `evals/run-evals.sh`, `evals/run-evals.ps1`, `.github/scripts/check-evals.sh`, `.github/scripts/check-evals.ps1`, and the `workflow-evals` module in `.github/starter-modules.json`; updated the README eval task list.
- Reason: the eval harness had no golden task covering the newly added PHP/Laravel stack overlays.
- Affected files: evals/tasks/laravel-component.md, evals/expected/laravel-component.checklist.md, evals/run-evals.sh, evals/run-evals.ps1, .github/scripts/check-evals.sh, .github/scripts/check-evals.ps1, .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-08-18 - Document Laravel component eval golden task"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-08-18 - Align ui-scaffold skill with stack instruction overlays

- Area: starter workflow, skills, runbooks
- Change type: enhancement
- Summary: updated `.github/skills/ui-scaffold/SKILL.md` to direct agents to read the repo's active UI-related instruction overlays (frontend, React, Next.js, Livewire, Inertia, Alpine, Filament) and consult official documentation for the installed versions before scaffolding; added Livewire, Inertia, Alpine, and Filament trigger examples plus two checklist items for overlay and documentation compliance; added matching example prompts to the `ui-scaffold` section of `docs/runbooks/skills.md`.
- Reason: the skill only covered React/Vue/Svelte component patterns and never referenced the stack instruction overlays added for Livewire, Inertia, Alpine, and Filament.
- Affected files: .github/skills/ui-scaffold/SKILL.md
- Related docs: DOC-CHANGELOG.md entry "2026-08-18 - Document ui-scaffold skill alignment"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-08-18 - Add database instruction overlays for SQLite, PostgreSQL, and MariaDB

- Area: starter instructions, manifest, runbooks, architecture docs
- Change type: enhancement
- Summary: added three new optional overlays — `sqlite.instructions.md`, `postgresql.instructions.md`, and `mariadb.instructions.md` — each with its own `applyTo` scope, official documentation references, and latest-stable/doc-first version rules; registered them as `overlay-sqlite`, `overlay-postgresql`, and `overlay-mariadb` in `.github/starter-modules.json` (version 1.2 to 1.3); added a "Relational database repos" section to `starter-composition.md`, a database overlays row to the `adopting-existing-github.md` artifact checklist, and new overlay nodes to the `ARCHITECTURE.md` module dependency graph.
- Reason: the starter had stack overlays for languages and frameworks but no database-specific instruction coverage.
- Affected files: .github/instructions/sqlite.instructions.md, .github/instructions/postgresql.instructions.md, .github/instructions/mariadb.instructions.md, .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-08-18 - Document database instruction overlays"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-08-18 - Add PHP ecosystem instruction overlays and fix the Laravel overlay

- Area: starter instructions, manifest, runbooks, architecture docs
- Change type: enhancement, fix
- Summary: replaced `.github/instructions/laravel.instructions.md` (previously an unregistered copy of the Python/SQL backend overlay) with real Laravel guidance; added six new overlays — `php.instructions.md` (PHP 8+ general), `filament.instructions.md` (Filament 5+), `livewire.instructions.md` (Livewire 4+), `inertia.instructions.md`, `alpine.instructions.md`, and `valkey.instructions.md` — each with its own `applyTo` scope, official documentation references, and latest-stable/doc-first version rules; registered all seven as overlay modules in `.github/starter-modules.json` (version 1.1 to 1.2); added a PHP/Laravel composition section to `starter-composition.md`, PHP/Laravel rows to the `adopting-existing-github.md` artifact checklist, and new overlay nodes to the `ARCHITECTURE.md` module dependency graph.
- Reason: the Laravel overlay existed but contained Python/SQL content and was not registered in the module manifest; the PHP, Laravel, Filament, Livewire, Valkey, Inertia, and Alpine stacks had no instruction coverage.
- Affected files: .github/instructions/laravel.instructions.md, .github/instructions/php.instructions.md, .github/instructions/filament.instructions.md, .github/instructions/livewire.instructions.md, .github/instructions/inertia.instructions.md, .github/instructions/alpine.instructions.md, .github/instructions/valkey.instructions.md, .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-08-18 - Document PHP ecosystem instruction overlays"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-08-08 - Add LTS-first and documentation-driven dependency rules across instructions

- Area: starter instructions, core, security, backend, frontend
- Change type: enhancement
- Summary: added a "Dependencies and Documentation" section to `core.instructions.md` mandating latest stable LTS releases, official documentation consultation, citation of references, and verification against current docs (not memory or AI-generated examples); added LTS preference, CVE/advisory checking, and docs-consultation rules to `security.instructions.md` Secure Configuration and Supply Chain section; expanded `backend.instructions.md` Dependency and Runtime Hygiene with LTS Python/library guidance and documentation-first rules; added a new "Dependencies" section to `frontend.instructions.md` with LTS Node.js, official docs consultation, citation of references, and advisory-checking rules.
- Reason: establish a cross-cutting rule that agents must always prefer latest stable LTS versions, consult official documentation (not memory or outdated sources), cite references, and check for advisories before using any dependency — applied consistently across core, security, backend, and frontend layers.
- Affected files: .github/instructions/core.instructions.md, .github/instructions/security.instructions.md, .github/instructions/backend.instructions.md, .github/instructions/frontend.instructions.md
- Related docs: DOC-CHANGELOG.md entry "2026-08-08 - Document LTS-first and documentation-driven dependency rules"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-08-08 - Improve instruction file coverage and cross-references

- Area: starter instructions, security, frontend, memory
- Change type: enhancement
- Summary: added a missing intro paragraph to `security.instructions.md` describing its role as the always-applied security baseline; added an "Error Handling" section to `frontend.instructions.md` covering error boundaries, console hygiene, and structured error states (previously absent); split the single "Quality" section in `frontend.instructions.md` into dedicated "Testing" and "Accessibility" sections for parity with the React overlay's structure; added a cross-reference from `core.instructions.md` Safety section to `security.instructions.md` making the layering explicit; added a cross-reference from `honcho-memory.instructions.md` to `memory.instructions.md` for the three-layer memory model.
- Reason: audit of all 12 instruction files found gaps: no intro on security instructions, no error handling guidance for frontend, mixed concerns in frontend Quality section, and missing cross-references that would help agents navigate the layered instruction model.
- Affected files: .github/instructions/security.instructions.md, .github/instructions/frontend.instructions.md, .github/instructions/core.instructions.md, .github/instructions/honcho-memory.instructions.md
- Related docs: DOC-CHANGELOG.md entry "2026-08-08 - Document instruction file improvements"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-07-25 - Document clone-as-template adoption path and initialize-new-project prompt

- Area: starter workflow, runbooks, onboarding, prompts
- Change type: docs, feature
- Summary: added a "Clone-As-Template (New Project Quickstart)" section to `starter-adoption.md` documenting the clone→rename→cleanup→add-app-code adoption path as a first-class alternative to copying `.github/` into an existing repo; added `app/` directory convention for application code separation; added a first-prompt step describing how to use the new `initialize-new-project` prompt to adapt all starter documentation (README, changelogs, overlays) to a specific project's name, tech stack, and goals; created `.github/prompts/initialize-new-project.prompt.md` as a reusable prompt for project initialization; registered the new prompt in `starter-modules.json`; updated `QUICKSTART.md` alternative-path note.
- Reason: users reported that cloning the starter directly and renaming it is their preferred workflow, but this path was undocumented; after cloning, users need a guided way to adapt all documentation to their specific project.
- Affected files: docs/runbooks/starter-adoption.md, QUICKSTART.md, .github/prompts/initialize-new-project.prompt.md, .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-07-25 - Document clone-as-template adoption path and initialize-new-project prompt"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-07-18 - Enrich problem-structuring skill with McKinsey Mind book insights

- Area: starter workflow, skills, evals
- Change type: enhancement
- Summary: enriched the `problem-structuring` skill with concepts from *The McKinsey Mind* (Rasiel & Friga): added Core Principles section (fact-based hypothesis-driven discipline, intuition-data balance with classification, one-day answer, key drivers); strengthened Step 1 (Frame the Problem) with initial hypothesis formation and business need identification; added key-driver focus to Steps 2-3; renamed Step 4 to "Design the Analysis" with confirm/refute framing, dependencies, and fallbacks; split Step 5 into "Gather the Data" and "Interpret the Results" with evidence classification and "so what?" test; expanded Step 7 (Synthesize and Communicate) with buy-in guidance and explicit decision ask; updated eval checklist and task to match enriched output format; updated the `structure-technical-problem` prompt with new deliverables and safety boundaries.
- Reason: incorporate deeper problem-solving rigor from the McKinsey Mind framework — initial hypothesis before decomposition, intuition-data balance, key-driver focus, distinct design-gather-interpret phases, and buy-in considerations.
- Affected files: .github/skills/problem-structuring/SKILL.md, .github/prompts/structure-technical-problem.prompt.md, evals/tasks/problem-structuring.md, evals/expected/problem-structuring.checklist.md
- Related docs: DOC-CHANGELOG.md entry "2026-07-18 - Document problem-structuring enrichment from McKinsey Mind"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-07-17 - Add McKinsey problem-structuring skill, prompt, and evals

- Area: starter workflow, skills, prompts, eval harness
- Change type: feature
- Summary: created the `problem-structuring` skill adapting McKinsey's 7-step problem-solving method (MECE decomposition, hypothesis-driven analysis, issue prioritization, Pyramid Principle synthesis, SCQA communication) for technical contexts; created the `structure-technical-problem` prompt for direct invocation; added eval task and expected checklist for problem-structuring behavior; updated eval runner scripts to include the new task and checklist; enhanced `analyst` and `tech-planner` agent definitions to reference the new frameworks; registered new skill, prompt, and eval assets in `starter-modules.json`.
- Reason: add structured problem-decomposition discipline to bridge the `analyst` → `tech-planner` chain for complex or ambiguous technical problems.
- Affected files: .github/skills/problem-structuring/SKILL.md, .github/prompts/structure-technical-problem.prompt.md, .github/agents/analyst.agent.md, .github/agents/tech-planner.agent.md, .github/starter-modules.json, evals/tasks/problem-structuring.md, evals/expected/problem-structuring.checklist.md, evals/run-evals.sh, evals/run-evals.ps1
- Related docs: DOC-CHANGELOG.md entry "2026-07-17 - Add problem-structuring skill, prompt, and agent enhancements"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-06-20 - Complete high-priority documentation
- Change type: docs, enhancement
- Summary: created MIGRATION.md with comprehensive v1.0 to v1.1 migration guide; created .github/examples/README.md documenting example usage patterns; created docs/runbooks/module-manifest-versioning.md explaining module manifest versioning strategy; created docs/ARCHITECTURE.md with Mermaid diagrams showing module relationships, validation workflows, and security layers.
- Reason: complete remaining high-priority documentation items to improve onboarding, migration, and understanding of the starter's architecture.
- Affected files: MIGRATION.md, .github/examples/README.md, docs/runbooks/module-manifest-versioning.md, docs/ARCHITECTURE.md
- Related docs: DOC-CHANGELOG.md entry "2026-06-20 - Complete high-priority documentation"
- Validation: bash .github/scripts/check-markdown-quality.sh passed
- Discrepancies or follow-up: none

### 2026-06-20 - Implement high-priority efficiency improvements

- Area: CI/CD, developer experience, validation
- Change type: feature, enhancement
- Summary: consolidated 4 separate GitHub Actions workflows into single validation.yml with parallel jobs; added VS Code tasks configuration for quick validation; added pre-commit hooks configuration; added Makefile with common validation targets; added validation timing to check-starter-workflow.sh; created QUICKSTART.md and TROUBLESHOOTING.md guides; added table of contents to README; created runbooks index.
- Reason: improve developer experience and reduce CI/CD overhead by consolidating workflows and providing quick access to common validation tasks.
- Affected files: .github/workflows/validation.yml, .vscode/tasks.json, .pre-commit-config.yaml, Makefile, QUICKSTART.md, TROUBLESHOOTING.md, README.md, docs/runbooks/INDEX.md, .github/scripts/check-starter-workflow.sh
- Related docs: DOC-CHANGELOG.md entry "2026-06-20 - Add developer experience documentation"
- Validation: bash .github/scripts/check-starter-workflow.sh passed; .github/scripts/check-starter-workflow.ps1 passed
- Discrepancies or follow-up: old workflow files (starter-validation.yml, markdown-quality.yml, hook-policy-tests.yml, skill-contract-tests.yml) need manual deletion

### 2026-06-07 - Enforce LF line endings for starter assets

- Area: Git normalization, starter scripts, and release hygiene
- Change type: config, fix
- Summary: added a repository `.gitattributes` policy that normalizes text files to LF and explicitly keeps shell scripts LF, then renormalized tracked text files so staged starter assets no longer carry CRLF working-tree endings.
- Reason: prevent Windows Git settings from rewriting `.sh` files to CRLF and producing line-ending warnings or Linux/CI execution issues before the new starter version is pushed.
- Affected files: .gitattributes, tracked text files normalized to LF
- Related docs: None
- Validation: `git check-attr text eol -- .github/scripts/check-evals.sh .github/scripts/check-hook-policy.sh evals/run-evals.sh` reported `eol: lf`; `git diff --cached --check` passed; `git ls-files --eol | Select-String 'w/crlf'` reported zero remaining CRLF working-tree text files; `bash .github/scripts/check-starter-workflow.sh` passed; `.github/scripts/check-starter-workflow.ps1` passed.
- Discrepancies or follow-up: none

### 2026-06-06 - Record pre-push starter release status

- Area: repository release tracking and starter validation status
- Change type: chore
- Summary: recorded the current pre-push status for the upgraded starter, including that the validation blocker fixes remain in place, the key workflow scripts are diagnostics-clean, and the starter is ready for push with the previously verified Bash and PowerShell validation suites.
- Reason: capture the release state before publishing this new starter version.
- Affected files: CHANGELOG.md, DOC-CHANGELOG.md
- Related docs: DOC-CHANGELOG.md entry "2026-06-06 - Document pre-push starter release status"
- Validation: static diagnostics for the recently touched Bash validation scripts reported no errors; repository diagnostics only reported local unresolved `actions/checkout@v4` warnings in GitHub Actions workflows; `bash .github/scripts/check-starter-workflow.sh` passed; `.github/scripts/check-starter-workflow.ps1` passed.
- Discrepancies or follow-up: none

### 2026-06-06 - Fix starter validation blockers

- Area: starter validation scripts and hook policy tests
- Change type: fix, test
- Summary: fixed PowerShell Markdown checker interpolation, made the Bash umbrella validator invoke helper scripts through `bash`, normalized shell script line endings, made Bash skill and prompt validators tolerate CRLF Markdown, aligned Bash hook policy matching to PCRE, handled final TSV rules without trailing newlines, and fixed PowerShell hook policy tests so fixtures pass as single command arguments without blocking on stdin.
- Reason: make both Bash and PowerShell starter validation suites run reliably from a Windows workspace and Ubuntu CI.
- Affected files: .github/scripts/check-markdown-quality.ps1, .github/scripts/check-starter-workflow.sh, .github/scripts/check-starter-skills.sh, .github/scripts/check-prompt-contracts.sh, .github/scripts/check-prompt-contracts.ps1, .github/scripts/check-hook-policy.sh, .github/scripts/check-hook-policy.ps1, .github/hooks/scripts/pre-tool-policy.sh, .github/hooks/scripts/pre-tool-policy.ps1, .github/hooks/policy-rules.tsv, .github/**/*.sh
- Related docs: DOC-CHANGELOG.md entry "2026-06-06 - Upgrade starter workflow documentation and overlays"
- Validation: `bash .github/scripts/check-starter-workflow.sh` passed; `.github/scripts/check-starter-workflow.ps1` passed
- Discrepancies or follow-up: none

### 2026-06-06 - Add production-grade starter validation and CI

- Area: starter validation, hooks, CI, MCP templates, eval scripts, module manifest
- Change type: feature, security, test, config
- Summary: added manifest, prompt, hook policy, MCP posture, Markdown quality, and eval harness validation scripts; expanded the hook policy rules; added CI workflows for starter validation, Markdown quality, hook policy fixtures, and skill contracts; expanded the module manifest to cover new core, optional, and overlay workflow assets; kept MCP templates disabled by default while adding reviewed template shapes.
- Reason: make the starter verify its own workflow contracts and guardrails as new prompts, skills, memory policy, runtime overlays, and eval assets are added.
- Affected files: .github/scripts/*.sh, .github/scripts/*.ps1, .github/hooks/policy-rules.tsv, .github/workflows/*.yml, .github/starter-modules.json, .vscode/mcp.json, evals/run-evals.sh, evals/run-evals.ps1
- Related docs: DOC-CHANGELOG.md entry "2026-06-06 - Upgrade starter workflow documentation and overlays"
- Validation: `bash .github/scripts/check-starter-workflow.sh` passed; `.github/scripts/check-starter-workflow.ps1` passed
- Discrepancies or follow-up: local workflow diagnostics could not resolve `actions/checkout@v4`, which appears to be an external-action resolver limitation rather than a YAML syntax issue

### 2026-03-16 - Add existing-.github adoption runbook to governance manifest

- Area: starter governance
- Change type: config
- Summary: updated the starter module manifest to include the new runbook for adopting this starter into repositories that already have a populated `.github` folder.
- Reason: make minimal-first existing-repo migration guidance part of core governance assets and keep manifest/file checks aligned.
- Affected files: .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-03-16 - Add existing-.github adoption runbook and wiring"
- Validation: bash .github/scripts/check-starter-workflow.sh passed
- Discrepancies or follow-up: none

### 2026-03-09 - Initialize source code changelog

- Area: repository governance
- Change type: chore
- Summary: added a dedicated source code changelog for tracking executable and behavior-affecting changes across any stack.
- Reason: provide a durable cross-reference point for implementation changes and code-to-doc alignment.
- Affected files: CHANGELOG.md
- Related docs: DOC-CHANGELOG.md entry "2026-03-09 - Initialize documentation changelog"
- Validation: not applicable
- Discrepancies or follow-up: none
