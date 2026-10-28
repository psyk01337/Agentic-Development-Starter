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

### 2026-10-28 - Rewrite the README around the problem it solves

- Area: README
- Change type: docs
- Summary: restructures the README from 439 to 305 lines. Leads with the problem the repository solves instead of an inventory, adds CI and count badges, replaces the 24-entry table of contents with eleven sections, adds a Mermaid diagram of the implement-verify-repair loop, and moves the per-check command list and the agent-registration checklist into collapsible blocks. Content that only existed in the README is preserved: the six-file reading order, the five coordinated agent registrations, and the common-mistakes list.
- Reason: the README is the first thing a visitor sees and it opened with a 24-item table of contents followed by dense prose, so the reason to care appeared well below the fold. The per-area sections also repeated what the runbooks already own.
- Affected files: README.md, DOC-CHANGELOG.md
- Related code: None - documentation only, no behavior change
- Review status: pending-review
- Discrepancies or follow-up: the badge count for guardrails is eleven, corrected from an overstatement of twelve made earlier in the day; the umbrella runs eleven checks and is itself the twelfth command. The README now asserts that the five agent registrations appear here and nowhere else, which is true today; if they move into a runbook, that section should become a link. No license badge is shown because the repository has no LICENSE file, which is worth resolving before inviting contributions.


### 2026-10-28 - Replace the app placeholder with an application guide

- Area: app/
- Change type: docs
- Summary: replaces the two-line placeholder in `app/README.md` with a guide covering the two layout patterns, the rule that the starter never validates application code, the commands an agent needs in order to verify work here, which optional overlays key off paths inside `app/`, and three environment traps found while testing (`CRLF` in `.sh`, `node` unresolvable from Git Bash, and framework-meaning folder names).
- Reason: the placeholder said only "put your application root here", so nothing in the repository told an agent landing in `app/` how to prove the application works. Verification commands are the difference between reported and observed results, and the starter's own checks cannot supply them.
- Affected files: app/README.md, DOC-CHANGELOG.md
- Related code: None - documentation only, no behavior change
- Review status: pending-review
- Discrepancies or follow-up: `app/` stays outside `.github/starter-modules.json` on purpose, so `check-markdown-quality` lints this file but nothing validates the application itself. If a future project wants its app inside the module manifest, that needs a decision about what an application module would even mean.

### 2026-10-27 - Document lastStage in the run record

- Area: agentic engine runbook
- Change type: docs
- Summary: documents `stage` versus `lastStage` in the state section, states that no code branches on `lastStage`, and points at the `history` array as the authoritative sequence.
- Reason: `lastStage` is written by the engine and surfaced by `status` and `report`, but nothing documented what it meant or why it differs from `stage` on a completed run. It was the only field in the run record with no stated contract.
- Affected files: docs/runbooks/agentic-engine.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Record the review stage as the last stage on completion"
- Review status: pending-review
- Discrepancies or follow-up: `lastStage` remains write-only inside the engine. If it never earns a consumer, dropping it is the simpler end state; documenting it now makes the decision reversible rather than accidental.

### 2026-10-27 - Record the manifest reset in initialize-new-project

- Area: initialize-new-project prompt
- Change type: docs
- Summary: adds a step that resets `"version"` in `.github/starter-modules.json` to `1.0.0` and names that version in the initial changelog entry.
- Reason: a live run of the prompt rewrote the README and cleared both changelogs exactly as instructed, and the repository then failed `check-starter-manifest` with `version 2.2.0 is not recorded in a CHANGELOG.md Summary line`. Two shipped instructions contradicted each other: the manifest check requires the current version in a Summary line, and the prompt said to remove every starter entry without saying to reset the version.
- Affected files: .github/prompts/initialize-new-project.prompt.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: None - the validator is unchanged; the prompt now satisfies it
- Review status: pending-review
- Discrepancies or follow-up: the prompt still leaves `maintainerAssetScan` at `true`, which is correct for a full clone because the project then maintains its own module manifest, but a project that deletes most modules will want to set it to `false`.

### 2026-10-27 - Record the build-feature golden task result

- Area: eval harness
- Change type: docs
- Summary: records the first live run of `evals/tasks/build-feature.md`, executed against an adopted project: a health-check slice with four tests, driven through the engine to `DONE`, graded against `evals/expected/build-feature.checklist.md` at 11 of 12 with the reviewer-separation item marked partial.
- Reason: the eval harness is described as manual/semi-automated, and no entry recorded that any golden task had actually been executed, so the checklist's grading vocabulary had no example to follow.
- Affected files: CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Record the review stage as the last stage on completion"
- Review status: pending-review
- Discrepancies or follow-up: the reviewer-separation checklist item cannot be satisfied in a single-agent session. `record --stage review` requires `reviewedBy` to differ from every implementer, but that is a string comparison, so one agent writing both values satisfies it. The item passes as a contract and not as a control, which matches how the repository describes its gates elsewhere, but the checklist wording does not say so.

### 2026-10-27 - Document the maintainer asset scan and the editor templates module

- Area: adoption runbooks, module manifest versioning guide, README
- Change type: docs, runbook
- Summary: records the `maintainerAssetScan` switch in the versioning guide and both adoption paths, adds the note that the umbrella assumes a complete module copy, documents the five registrations the supervisor validator requires for any agent file, and corrects the README claim that optional modules include MCP templates to describe the default-disabled `editor-templates` module that now exists.
- Reason: the existing-project path told readers to copy assets and run the checks, but following it produced registration errors for their own files and could overwrite their `.vscode` settings. A follow-up test showed an adopting repo's own agent file fails the supervisor validator, and the README listed three of the five registrations that check requires, so the remedy was not discoverable from the docs.
- Affected files: docs/runbooks/module-manifest-versioning.md, docs/runbooks/starter-adoption.md, docs/runbooks/adopting-existing-github.md, QUICKSTART.md, README.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Stop the asset scan from blocking adopters and split editor templates out"
- Review status: pending-review
- Discrepancies or follow-up: a partial merge still produces `Manifest-listed file does not exist` errors for modules that were not copied, which is now stated rather than fixed. Trimming the manifest to match a partial copy is the reader's decision, because only they know which modules they intend to ship.

### 2026-10-27 - Fix the baseline copy lists and scope what they promise

- Area: QUICKSTART, starter adoption runbook
- Change type: docs
- Summary: adds `.github/instructions/memory.instructions.md` to both baseline copy lists and states in QUICKSTART that the list is the always-on rule set rather than a copyable module, pointing readers at `.github/starter-modules.json` for a copy whose checks pass.
- Reason: a workflow test copied exactly the documented baseline into a scratch repo and the manifest check reported `memory.instructions.md` missing, because both lists named `core` and `security` and stopped. The same test showed the list cannot produce a passing repo on its own, since the manifest also requires the validation scripts, role definitions, and overlays, so the wording promised more than the list delivered.
- Affected files: QUICKSTART.md, docs/runbooks/starter-adoption.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: None — documentation only, no behavior change
- Review status: pending-review
- Discrepancies or follow-up: copying the corrected list still leaves 220 manifest errors from overlays, scripts, evals, and editor templates. That is correct for a rule-only baseline and is now stated; a future pass could publish a minimal copyable module if partial adoption turns out to be a common request.

### 2026-10-27 - Document what the manifest validators actually enforce

- Area: module manifest versioning guide
- Change type: docs, runbook
- Summary: rewrites the guide's validation section as a table that names each enforced rule and marks a missed version bump as not enforced, and explains why the changelog check matches `- Summary:` lines rather than the whole file.
- Reason: the guide described the versioning contract as if all of it were automated. Two rules in it are not, and one of them is the only rule that needs human judgement, so a reader had no way to tell which failures a green check would catch.
- Affected files: docs/runbooks/module-manifest-versioning.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Enforce the changelog side of the manifest versioning contract"
- Review status: pending-review
- Discrepancies or follow-up: the guide states the changelog rule as "version appears in a Summary line", which is the strongest form a stateless check can hold. A version quoted only in a Validation or Affected files line does not satisfy it, and that is intentional: the Summary is where the version transition belongs.

### 2026-10-27 - Document the write-set boundary and the manifest coverage check

- Area: agentic engine runbook, module manifest versioning guide
- Change type: docs, runbook
- Summary: records in `docs/runbooks/agentic-engine.md` that a write-set entry the engine cannot compare against a changed file is refused at `init`, naming each rejected shape, and states why the boundary is treated as structural rather than advisory. Adds a "What The Validators Enforce" table to the versioning guide that names the one rule left to review.
- Reason: the runbook promised "a bounded write set of explicit paths" while `init` only enforced wildcards and the unbounded indicator words, so a reader could reasonably conclude that `../outside.py` was permitted because nothing said otherwise. The versioning guide likewise demanded a changelog entry for every manifest change without stating whether anything checked it.
- Affected files: docs/runbooks/agentic-engine.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Close three QA findings in the engine and the manifest"
- Review status: pending-review
- Discrepancies or follow-up: the manifest now lists 229 of 233 tracked files. The four remaining are root tooling (`Makefile`, `.gitignore`, `.gitattributes`, `.pre-commit-config.yaml`) and stay outside any module on purpose, because a module that shipped them would fight the adopting repo's own tooling.

### 2026-10-27 - Drop the month stamp from the README title and name the new eval

- Area: README
- Change type: docs
- Summary: changes the README title from "(VS Code, August 2026 Workflow)" to "(VS Code Agent Workflows)" and adds end-to-end feature delivery to the evaluation-harness task list.
- Reason: the month in the title had already been carried forward twice (June 2026 to August 2026) and was stale again by two months. A calendar stamp on line 1 of a living document reads as an abandoned project and needs manual upkeep every month. The eval list also predated the `build-feature` task.
- Affected files: README.md, DOC-CHANGELOG.md
- Related code: None — documentation only, no behavior change
- Review status: pending-review
- Discrepancies or follow-up: if the month stamp was carrying a real meaning, such as the VS Code release the workflow was verified against, that belongs in a dated line near the validation section rather than in the title. Restoring a month would reintroduce the same drift.

### 2026-10-27 - Document the trimmed baseline, the merged skill, and ADR 0007

- Area: security instructions, skills runbook, engineering team runbook, supervisor runbook, ADR
- Change type: docs, runbook
- Summary: documents the two-mode `session-compaction` skill in place of the removed `session-compactor`, updates the cross-cutting skill lists in the engineering team and supervisor runbooks, and adds ADR 0007 recording why nested delegation stays disabled.
- Reason: three runbooks listed a skill that no longer exists, and one described the old state-versus-history split as if the two skills were still separate. The nested delegation limit was documented only as a policy value with no explanation of when it would be revisited.
- Affected files: docs/runbooks/skills.md, docs/runbooks/engineering-team.md, docs/runbooks/supervisor-orchestration.md, docs/adr/0007-nested-delegation-disabled.md, .github/instructions/security.instructions.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Trim always-on security, add evals, consolidate skills, split validators"
- Review status: pending-review
- Discrepancies or follow-up: the trimmed security baseline is shorter but not reorganized, so a future pass could merge the remaining bullet pairs if the rule count grows again. ADR 0007 is `Proposed`; it should move to `Rejected` if the answer is still "serialize it" at review time, rather than staying open indefinitely.

### 2026-10-27 - Correct the stale module example in the versioning guide

- Area: module manifest versioning guide
- Change type: docs
- Summary: corrects Pattern 3, which showed `"id": "feature-approval-handoffs"` with `"kind": "optional"`; the real module is `overlay-approval-gated-orchestration` with `"kind": "overlay"`. The example file list also omitted the schema, the runbook, and ADR 0001, and adds a note on when to use `optional` versus `overlay`.
- Reason: a reader copying the example would create a module whose id does not follow the `overlay-` convention and whose kind contradicts how the real approval-gated overlay ships.
- Affected files: docs/runbooks/module-manifest-versioning.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Bump the manifest to 2.0.0 and enforce the version shape"
- Review status: pending-review
- Discrepancies or follow-up: `MIGRATION.md` exists only in the local working tree and is gitignored, so the migration-guidance gap recorded in `.forlocal/supervisor-orchestration-review-packet.md` cannot be closed in the tracked repo until a tracked equivalent is agreed.

### 2026-10-27 - Align the docs with the root entry point and the catalog rename

- Area: README, QUICKSTART, TROUBLESHOOTING, module manifest versioning guide, root entry point
- Change type: docs, runbook
- Summary: adds the root `AGENTS.md` and `.github/agent-catalog.md` to the README folder structure and surface-selection table, adds the root file to the QUICKSTART baseline copy list, adds a "Rename a File" procedure to the versioning guide, adds an "Agent ignores the repo rules" troubleshooting entry, and points the root entry point at the composition runbook.
- Reason: four reader-facing documents still described the starter without the cross-agent entry point, the versioning guide had no procedure for renaming a file even though that is the change that just occurred, and there was no troubleshooting path for the most likely confusion: an agent that follows general good practice but not this repository's rules.
- Affected files: README.md, QUICKSTART.md, TROUBLESHOOTING.md, AGENTS.md, docs/runbooks/module-manifest-versioning.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Bump the manifest to 2.0.0 and enforce the version shape"
- Review status: pending-review
- Discrepancies or follow-up: `docs/runbooks/module-manifest-versioning.md` still describes the manifest as consumed by "CI workflows"; no workflow currently reads the version field. The new validator enforces shape only, so a missed major bump remains a review responsibility.

### 2026-10-27 - Document the agent catalog rename

- Area: ADRs, composition and adoption runbooks, agent catalog
- Change type: docs, runbook
- Summary: records that the agent catalog is now `.github/agent-catalog.md`, explains in the composition runbook why it is deliberately not named `AGENTS.md`, and rewrites the three stale ADR line-number citations as section references.
- Reason: a reader who found two `AGENTS.md` files had no way to tell which one a harness loads, and the ADR line anchors had already drifted so that `AGENTS.md:206` pointed at an unrelated table row.
- Affected files: .github/agent-catalog.md, docs/adr/0001-approval-gated-orchestration-overlay.md, docs/adr/0003-supervisor-orchestration-overlay.md, docs/adr/0004-adapter-bound-delegation.md, docs/runbooks/starter-composition.md, docs/runbooks/starter-adoption.md, AGENTS.md, README.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Rename the agent catalog away from the AGENTS.md name"
- Review status: pending-review
- Discrepancies or follow-up: the rename is a `core-governance-change` by the policy's own definition, since it edits `orchestration-policy.json` text, the agent catalog, and the validator twins. ADR 0003 and ADR 0004 were updated in place rather than superseded because only path citations changed, not the decisions they record. Earlier `DOC-CHANGELOG.md` entries keep the old path for the same reason as the source changelog.

### 2026-10-27 - Document where AGENTS.md loads from

- Area: starter composition runbook, starter adoption runbook, README
- Change type: docs, runbook
- Summary: adds a cross-agent entry-point row to the instruction-loading table and three bullets that separate the root `AGENTS.md` from `.github/AGENTS.md`, state that the root file must stay at the repository root, and record which harnesses read `AGENTS.md` versus `CLAUDE.md`. Adds the root file to the adoption tiers and to the README reading order.
- Reason: the loading table listed three layers and omitted `AGENTS.md`, so the only `AGENTS.md` anyone could find was the catalog in `.github/`, which led to the reasonable but wrong conclusion that `AGENTS.md` is a Claude-only file that this repository does not use.
- Affected files: docs/runbooks/starter-composition.md, docs/runbooks/starter-adoption.md, README.md, AGENTS.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Add the cross-agent root entry point"
- Review status: pending-review
- Discrepancies or follow-up: the per-harness discovery rules come from the VS Code custom instructions documentation as of 2026-10-27. Harnesses change discovery behavior, so recheck the table when a host adds or renames its instruction file.

### 2026-10-27 - Document the delegated subagent contract

- Area: agent catalog, engineering team runbook, supervisor orchestration skill
- Change type: docs, runbook
- Summary: adds a "Delegated Subagent Contract" section to the agent catalog and a statelessness paragraph to the engineering team runbook, and adds the same rules to the supervisor skill and the supervisor agent. Covers the four-part payload (goal, context, allowed actions, expected result), `needs-clarification` as a terminal result, and the difference between the guided handoff allow-list and the delegable `specialistAllowList`.
- Reason: readers had no way to know that a delegated subagent cannot ask a follow-up question, keep a todo list, or see the earlier conversation, so handoffs were written as conversations rather than as self-contained payloads.
- Affected files: .github/AGENTS.md, docs/runbooks/engineering-team.md, .github/skills/supervisor-orchestration/SKILL.md, .github/agents/delegation-supervisor.agent.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-27 - Encode the delegated subagent contract"
- Review status: pending-review
- Discrepancies or follow-up: the statelessness rule is stated as a host-independent contract because Local and Copilot harnesses differ in tool names and available tools; a host that supports richer subagent interaction may relax it later. The `user-invocable: false` option is documented by VS Code but deliberately not applied — the nine specialists are intended to be directly invocable by a human as well as delegable.

### 2026-10-26 - Document the instruction loading model

- Area: starter composition runbook, README
- Change type: docs, runbook
- Summary: adds a "How Instruction Files Load" section explaining the baseline, always-on, and scoped layers, the token cost of overlapping globs, the Phaser overlay choice, and the new `applyTo` requirement; adds a loading-model pointer to the README core-versus-optional section.
- Reason: users could not tell which instructions are always injected, why overlapping overlays cost context, or why an instruction file silently has no effect.
- Affected files: docs/runbooks/starter-composition.md, README.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-26 - Reduce always-on context and validate instruction frontmatter"
- Review status: pending-review
- Discrepancies or follow-up: the loading table describes GitHub Copilot behavior; other hosts may load instructions differently.

### 2026-10-25 - Document the four delivery skills and core baseline

- Area: skills runbook, README, core instructions
- Change type: docs, runbook
- Summary: documents `database-migration`, `dependency-upgrade`, `refactor-safely`, and `threat-modeling` with example prompts, updates the README skills summary, and records the new core sections.
- Reason: make the new delivery playbooks discoverable and record the tightened baseline.
- Affected files: README.md, docs/runbooks/skills.md, .github/instructions/core.instructions.md, .github/starter-modules.json, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add four delivery skills and tighten the core baseline"
- Review status: pending-review
- Discrepancies or follow-up: skills are playbooks; the core additions are prompt-level rules.
### 2026-10-25 - Document the engine, ingestion, and push troubleshooting

- Area: README, QUICKSTART, TROUBLESHOOTING
- Change type: docs, onboarding, reference
- Summary: adds an Agentic Engine section and TOC entry to the README, lists `docs/inputs.md` and `.agentic/state/` in the folder structure, and adds the engine check to the validation commands. QUICKSTART now requires Python 3.9+, describes blocked-run escalation in the daily loop, and links the engine runbook and troubleshooting guide. TROUBLESHOOTING gains sections for engine failures, document ingestion, and Git push authentication, and corrects the prompt heading names to match the validator.
- Reason: the repo gained a deterministic engine, document routing, and new prompt contracts, but the user-facing guides did not cover them. The prompt section named headings the validator does not accept.
- Affected files: README.md, QUICKSTART.md, TROUBLESHOOTING.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entries "2026-10-25 - Fix wall-clock budget precision and the flaky budget test" and "2026-10-25 - Close the fifth agentic engine review findings"
- Review status: pending-review
- Discrepancies or follow-up: the troubleshooting sections are operational guidance; the engine runbook remains the canonical contract.
### 2026-10-25 - Document the fifth agentic engine hardening

- Area: agentic-engine runbook
- Change type: docs, runbook
- Summary: documents state validation, the query-string rejection rule for URL evidence, budget checks on `next` and `approve`, the evidence-stage field in the blocker, and the expanded self-test inventory.
- Reason: the fifth QA and review pass changed enforceable behavior.
- Affected files: docs/runbooks/agentic-engine.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Close the fifth agentic engine review findings"
- Review status: pending-review
- Discrepancies or follow-up: signed links must use `artifact:`; URL query strings are rejected.

### 2026-10-25 - Document the fourth agentic engine hardening

- Area: agentic-engine runbook, repository hygiene
- Change type: docs, runbook
- Summary: documents the credential-free URL rule, the closed input-error contract, and the expanded self-test inventory; records the Python bytecode ignore rule.
- Reason: the fourth QA and review pass changed enforceable behavior and error output.
- Affected files: docs/runbooks/agentic-engine.md, .gitignore, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Close the fourth agentic engine review findings"
- Review status: pending-review
- Discrepancies or follow-up: signed query strings are not rejected; operators should avoid them in evidence pointers.

### 2026-10-25 - Document the third agentic engine hardening

- Area: agentic-engine runbook
- Change type: docs, runbook
- Summary: documents the Python 3.9 requirement, repository-bounded evidence with scheme fallback for out-of-repo artifacts, host-required URLs, `--force` limited to the `implement` stage, and the implementer list exposed at review.
- Reason: the third QA and review pass changed enforceable behavior.
- Affected files: docs/runbooks/agentic-engine.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Close the third agentic engine review findings"
- Review status: pending-review
- Discrepancies or follow-up: out-of-repo evidence must use a scheme; identities remain self-declared.

### 2026-10-25 - Document the second agentic engine hardening

- Area: agentic-engine runbook
- Change type: docs, runbook
- Summary: documents implementer and reviewer fields, reviewer separation, stricter evidence rules, OS-aware case folding, `--force` restrictions, `report` exit codes, task class and surface validation, and the history cap.
- Reason: the second QA and review pass changed enforceable behavior.
- Affected files: docs/runbooks/agentic-engine.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Close the second agentic engine review findings"
- Review status: pending-review
- Discrepancies or follow-up: identity is self-declared; separation is enforced, authentication is not.

### 2026-10-25 - Document the agentic engine hardening

- Area: agentic-engine runbook
- Change type: docs, runbook
- Summary: documents the hardened stage contract, evidence schemes, bounded write-set rule, signature derivation, approval `requestedBy` requirement, per-run lock, budget blocking with exit `3`, and the expanded self-test inventory.
- Reason: the QA and code-review pass changed enforceable behavior; the runbook must match it.
- Affected files: docs/runbooks/agentic-engine.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Close the agentic engine QA and review findings"
- Review status: pending-review
- Discrepancies or follow-up: evidence schemes are a closed list by design.

### 2026-10-25 - Document the agentic engine and bounded repair loop

- Area: runbooks, skills, README, QUICKSTART
- Change type: docs, runbook
- Summary: adds the engine runbook and `repair-loop` skill, documents the loop in the engineering team runbook, supervisor skill, supervisor agent, and team prompt, and adds the engine to README, QUICKSTART, the skills runbook, and the runbook index.
- Reason: make the deterministic loop discoverable, including its stage contract, retry policy, blocker reasons, and exit codes.
- Affected files: docs/runbooks/agentic-engine.md, docs/runbooks/engineering-team.md, docs/runbooks/skills.md, docs/runbooks/INDEX.md, .github/skills/repair-loop/SKILL.md, .github/skills/supervisor-orchestration/SKILL.md, .github/agents/delegation-supervisor.agent.md, .github/prompts/run-engineering-team.prompt.md, README.md, QUICKSTART.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add the deterministic agentic engine and bounded repair loop"
- Review status: pending-review
- Discrepancies or follow-up: the engine enforces the contract when invoked; it cannot prevent a host from ignoring it. Time budget is checked at transitions.

### 2026-10-25 - Document the domain skills and overlays

- Area: skills, instructions, runbooks
- Change type: docs, runbook
- Summary: documents the five new domain skills and three instruction overlays in README, the skills runbook, starter composition, and existing-repo adoption guidance.
- Reason: make the new domain coverage discoverable and set the enablement and safety boundaries.
- Affected files: README.md, docs/runbooks/skills.md, docs/runbooks/starter-composition.md, docs/runbooks/adopting-existing-github.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add domain skills and overlays"
- Review status: pending-review
- Discrepancies or follow-up: the domain overlays are optional. Reverse engineering and binary analysis require authorization, isolation, and sanitized artifacts; samples must not be committed.

### 2026-10-25 - Document the engineering team operating layer

- Area: runbooks, prompts, AGENTS.md
- Change type: docs, runbook
- Summary: adds the engineering team runbook and prompt, documents the team topology and task assignment contract in `AGENTS.md`, extends the supervisor skill and agent with team management, and adds the team flow to README, QUICKSTART, and the `agentic-dev` runbook.
- Reason: make the full SDLC team model discoverable and usable without changing the one-level delegation policy.
- Affected files: docs/runbooks/engineering-team.md, .github/prompts/run-engineering-team.prompt.md, .github/AGENTS.md, .github/agents/delegation-supervisor.agent.md, .github/skills/supervisor-orchestration/SKILL.md, README.md, QUICKSTART.md, docs/runbooks/agentic-dev.md, docs/runbooks/INDEX.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add the engineering team operating layer"
- Review status: pending-review
- Discrepancies or follow-up: nested team leads are deferred; v1 keeps exactly one delegation level. The task board is session or task-scoped, not a committed workflow-state file.

### 2026-10-25 - Ignore local vNext and architecture workflow prompts

- Area: repository root, local-only inputs
- Change type: docs, chore
- Summary: records that `update-09142026.md` and `update-09262026.md` are local historical update prompts, adds them to `.gitignore`, and removes them from the tracked tree.
- Reason: they are predecessor planning notes, not starter assets, and should not be shipped with the repository.
- Affected files: .gitignore, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Ignore local update prompts"
- Review status: pending-review
- Discrepancies or follow-up: the files remain on disk and are ignored. Durable decisions from them are already recorded in the existing changelogs, ADRs, and prompts.

### 2026-10-25 - Make drop-and-route the default app start

- Area: QUICKSTART, README
- Change type: docs
- Summary: restructures QUICKSTART Path A so dropping planning documents and running `route-project-inputs` is the default setup path; `initialize-new-project` is the fallback when no documents exist. README Quick Start mirrors the same order and names the router as the single entry point.
- Reason: the user wants to drop one or more Markdown files and have the agent decide where each belongs, instead of selecting prompts file by file.
- Affected files: QUICKSTART.md, README.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add project input routing"
- Review status: pending-review
- Discrepancies or follow-up: docs-only; the router remains prompt-level orchestration, not a file watcher or binary parser.

### 2026-10-25 - Document project input routing

- Area: prompts, QUICKSTART, README, runbooks
- Change type: docs, runbook
- Summary: adds the router prompt to the README prompt list and daily frame step, replaces the single-document callout in QUICKSTART with the router flow, adds the routing chain to the `agentic-dev` runbook, and adds workflow destinations plus a routing log to `docs/inputs.md`.
- Reason: make one dropped-files prompt the default intake path and remove per-file prompt selection.
- Affected files: .github/prompts/route-project-inputs.prompt.md, README.md, QUICKSTART.md, docs/runbooks/agentic-dev.md, docs/inputs.md, .github/starter-modules.json, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add project input routing"
- Review status: pending-review
- Discrepancies or follow-up: the router is prompt-level orchestration; no automatic parser, watcher, or binary-format support is added. Unsupported sources must be converted.

### 2026-10-25 - Document the document-ingestion eval and inputs template

- Area: evals, docs, README
- Change type: docs
- Summary: records the new golden task and checklist, their registration in both eval runners and both `check-evals` scripts, the README evaluation coverage, `docs/inputs.md`, the supported-format and provenance guidance, and the downstream-repo guard against overwriting starter docs; notes that the prompt remains a prompt until repeated use justifies promoting it to a skill.
- Reason: make document ingestion verifiable and give users a tracked intake and provenance path.
- Affected files: evals/tasks/ingest-project-docs.md, evals/expected/ingest-project-docs.checklist.md, README.md, docs/inputs.md, .github/prompts/ingest-project-docs.prompt.md, .github/starter-modules.json, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add the document-ingestion eval and inputs template"
- Review status: pending-review
- Discrepancies or follow-up: the golden task is manual/semi-automated. The prompt remains a prompt until repeated use justifies promoting it to a skill.

### 2026-10-25 - Document project documentation ingestion

- Area: prompts, QUICKSTART, README, agentic-dev runbook
- Change type: docs, runbook
- Summary: adds the `ingest-project-docs` prompt to the README prompt list and daily frame step, inserts the intake step in QUICKSTART Path A, adds the project documentation intake chain to the agentic-dev runbook, and points existing-repo adopters at the prompt in the adoption runbook.
- Reason: make the PRD/design/API intake path discoverable before the first feature.
- Affected files: README.md, QUICKSTART.md, docs/runbooks/agentic-dev.md, docs/runbooks/adopting-existing-github.md, .github/prompts/ingest-project-docs.prompt.md, .github/starter-modules.json, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add project documentation ingestion"
- Review status: pending-review
- Discrepancies or follow-up: docs describe the prompt; no document parser or format converter is added. Unreadable formats must be converted or reported as a blocked input.

### 2026-10-25 - Rewrite QUICKSTART for the app fast path

- Area: QUICKSTART, README quick start
- Change type: docs
- Summary: rewrites QUICKSTART as a 10-minute path from clone to first feature, covering clone-as-template, `initialize-new-project`, the `app/` layout, `build-feature`, validation, and commit; adds the existing-app path, Team Mode guidance, the daily loop, and the framework-freeze rule. README now points to QUICKSTART as the first start-here step and replaces the old copy-only quick start with the app fast path. The runbook index label no longer calls the guide a 5-minute setup.
- Reason: the previous quick start assumed copying `.github` into an existing repo and did not show how to reach a running app or use the new `build-feature` front door.
- Affected files: QUICKSTART.md, README.md, docs/runbooks/INDEX.md, DOC-CHANGELOG.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: docs-only; run Markdown quality checks. The application skeleton is still created by the first feature, not by this guide.

### 2026-10-25 - Document the build-feature front door

- Area: prompts, runbooks, README
- Change type: docs
- Summary: adds the `build-feature` prompt, the README prompt coverage and delivery-loop mention, and the `agentic-dev.md` front-door section; records the manifest registration and the one-command-per-feature workflow.
- Reason: make the existing guided chains discoverable through one entry point instead of requiring the user to choose among planning, implementation, review, and test-plan prompts.
- Affected files: .github/prompts/build-feature.prompt.md, README.md, docs/runbooks/agentic-dev.md, .github/starter-modules.json, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add the build-feature front-door prompt"
- Review status: pending-review
- Discrepancies or follow-up: the prompt routes existing agents; it does not add a new orchestration runtime. QA execution remains a `qa` or human handoff.
### 2026-10-25 - Document the bounded repo self-improvement loop

- Area: runbooks, prompts, README
- Change type: docs, runbook
- Summary: adds the self-improvement runbook, the `improve-repo` prompt, the runbook index entry, and the README prompt coverage; records the on-demand versus scheduled autonomy boundary and the `process-improvement` to `qa` validation handoff.
- Reason: document the loop that lets an agent improve the starter in one bounded iteration without building a scheduler or widening an agent's tool boundary.
- Affected files: docs/runbooks/self-improvement.md, docs/runbooks/INDEX.md, .github/prompts/improve-repo.prompt.md, README.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Add the bounded repo self-improvement loop"
- Review status: pending-review
- Discrepancies or follow-up: scheduled unattended execution is deferred; the loop is invoked manually. Validation remains a `qa` or human handoff because `process-improvement` has no `execute` capability.

### 2026-10-25 - Document the Phase 11 review close-out

- Area: supervisor runbook, Phase 11 review record
- Change type: docs, runbook
- Summary: corrects the supervisor runbook's fixture total from forty-seven to forty-six and records the independent-review close-out for Phase 11, including the manifest registration and the two findings it resolved.
- Reason: the runbook's total contradicted its own forty-three-negative-plus-three-positive breakdown and the changelog's forty-six-fixture record; the 2026-10-09 entries still described Phase 11 review as outstanding.
- Affected files: docs/runbooks/supervisor-orchestration.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-25 - Close the Phase 11 review findings"
- Review status: pending-review
- Discrepancies or follow-up: the harness remains manual/semi-automated; the manifest check does not detect unlisted eval assets, so the four required lists remain the deletion guard.

### 2026-10-09 - Document the decision-trail golden task

- Area: eval harness, README evaluation section
- Change type: docs
- Summary: records the new decision-trail golden task and expected checklist, their registration in both eval runners and both `check-evals` structure checks, and the README evaluation-coverage sentence update.
- Reason: the Phase 11 QA handoff asked for behavioral verification of the decision-trail skill; the docs land in the same change so the harness catalog matches the shipped files.
- Affected files: evals/tasks/decision-trail.md, evals/expected/decision-trail.checklist.md, README.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-10-09 - Add the decision-trail golden task (Phase 11 QA follow-up)"
- Review status: pending-review
- Discrepancies or follow-up: the harness remains manual/semi-automated; no runner executes golden tasks automatically. The eval checks and both umbrellas ran green in the same session that landed the docs. Phase 11 independent review completed on 2026-10-25; the two findings it raised are closed in the 2026-10-25 entry.

### 2026-09-30 - Document the Phase 11 review repairs

- Area: skill guidance, skills runbook
- Change type: docs, runbook
- Summary: the decision-trail checklist retains advisory fields, and the skills runbook now states how the trail differs from landed-change changelogs, durable-decision ADRs, and continuation briefs.
- Reason: resolve the two Phase 11 review findings and align the runbook with the earlier documentation entry.
- Affected files: .github/skills/decision-trail/SKILL.md, docs/runbooks/skills.md, CHANGELOG.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-09-30 - Address the Phase 11 review findings"
- Review status: pending-review
- Discrepancies or follow-up: independent review is outstanding; the three twin pins remain unchanged.

### 2026-09-27 - Document the decision-trail skill (vNext Phase 11)

- Area: skills runbook, supervisor runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/skills.md` gains a `decision-trail` entry under Optional Overlay Skills (after `session-compactor`) that records the placement discrepancy and the division of labor: changelogs record landed changes, ADRs record durable one-time decisions, `session-compactor` produces continuation briefs, and the decision trail records task-time decisions with evidence pointers; the trail is never workflow state and never a completion declaration. Two example prompts accompany the entry. The supervisor runbook's behavioral notes gain an eighth bullet naming the skill.
- Reason: vNext Phase 11 lands the decision-trail skill; the docs land in the same change so the skill catalog and the runbook describe the shipped skill.
- Affected files: docs/runbooks/skills.md, docs/runbooks/supervisor-orchestration.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-09-27 - Add the decision-trail skill (vNext Phase 11)"
- Review status: pending-review
- Discrepancies or follow-up: `decision-trail` is a repo-wide audit skill but is registered inside the supervisor orchestration overlay's manifest files for program-pattern continuity, matching `prose-cleanup` and `session-compactor`; the placement discrepancy is recorded here deliberately. The division of labor is stated in the skills runbook entry and in the skill body itself, and is unpinned prose beyond the three twin assertions.

### 2026-09-27 - Restore the architecture-reviewer frontmatter (user decision A)

- Area: agents
- Change type: docs
- Summary: records the third specialist-frontmatter restore and the user's explicit choice of option A (restore the sole-holder rule) over option B (a second delegation holder requiring an ADR).
- Reason: the user re-added the `agent` tool to `architecture-reviewer.agent.md`; the restore and the decision are recorded for traceability.
- Affected files: DOC-CHANGELOG.md, CHANGELOG.md, .github/agents/architecture-reviewer.agent.md
- Related code: CHANGELOG.md entry "2026-09-27 - Restore the architecture-reviewer frontmatter (user decision A)"
- Review status: pending-review
- Discrepancies or follow-up: option B remains open as a policy decision.

### 2026-09-27 - Close the Phase 10 review follow-ups

- Area: skills, agents, changelogs
- Change type: docs
- Summary: records the Phase 10 review close-out: the `session-compactor` division-of-labor wording is softened (S2), and the `code-reviewer` frontmatter restore (OS-1) is documented alongside the earlier `architecture-reviewer` restore.
- Reason: code review of the Phase 10 slice returned pass with S1, S2, OS-1; the close-out is recorded here.
- Affected files: DOC-CHANGELOG.md, CHANGELOG.md, .github/skills/session-compactor/SKILL.md, .github/agents/code-reviewer.agent.md
- Related code: CHANGELOG.md entry "2026-09-27 - Close the Phase 10 review follow-ups"
- Review status: pending-review
- Discrepancies or follow-up: none open for this slice; the second-delegation-holder question stays an ADR-level decision.

### 2026-09-27 - Document the session-compactor skill (vNext Phase 10)

- Area: skills runbook, supervisor runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/skills.md` gains a `session-compactor` entry under Optional Overlay Skills (after `prose-cleanup`) that records the placement discrepancy and the division of labor with the core `session-compaction` skill: `session-compaction` preserves handoff-time state (current plan, acceptance criteria, validation evidence, next recommended action), while `session-compactor` compresses a long working history into the ten-field compact continuation brief and discards conversational filler; the brief is not workflow-state storage and is not a completion declaration. Two example prompts accompany the entry. The supervisor runbook's behavioral notes gain a seventh bullet naming the skill.
- Reason: vNext Phase 10 lands the session-compactor skill; the docs land in the same change so the skill catalog and the runbook describe the shipped skill.
- Affected files: docs/runbooks/skills.md, docs/runbooks/supervisor-orchestration.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-09-27 - Add the session-compactor skill (vNext Phase 10)"
- Review status: pending-review
- Discrepancies or follow-up: `session-compactor` is a repo-wide context-compaction skill but is registered inside the supervisor orchestration overlay's manifest files for program-pattern continuity, matching `prose-cleanup`; the placement discrepancy is recorded here deliberately. The division of labor against core `session-compaction` is stated in the skills runbook entry and in the skill body itself, and is unpinned prose beyond the three twin assertions.

### 2026-09-27 - Close the Phase 9 review follow-ups

- Area: changelogs
- Change type: docs
- Summary: records the Phase 7/Phase 8 review-status asymmetry (S1) so a reader can tell the Phase 7 close-out's `pending-review` is a deliberate deferral, not a missed flip; the Phase 8 close-out stays `reviewed` and the Phase 9 entries stay `pending-review`.
- Reason: code review of the Phase 9 slice returned needs-revision; S1 closes in this change alongside W1 and S2 in the code log.
- Affected files: DOC-CHANGELOG.md, CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-09-27 - Close the Phase 9 review follow-ups"
- Review status: pending-review
- Discrepancies or follow-up: none open for this slice.

### 2026-09-27 - Document the prose-cleanup skill (vNext Phase 9)

- Area: skills runbook, supervisor runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/skills.md` gains a `prose-cleanup` entry under Optional Overlay Skills clarifying that the skill applies repo-wide (agent responses, ADRs, PR descriptions, documentation, handoffs, code comments) even though it ships under the supervisor orchestration overlay's manifest section, with two example prompts. The supervisor runbook's behavioral notes gain a sixth bullet naming the skill. The previous top entry "2026-09-26 - Close the Phase 8 review follow-up" flips from pending-review to reviewed (architecture gate Part A approved it).
- Reason: vNext Phase 9 lands the prose-cleanup skill; the docs land in the same change so the skill catalog and the runbook describe the shipped skill and its repo-wide scope.
- Affected files: docs/runbooks/skills.md, docs/runbooks/supervisor-orchestration.md, DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-09-27 - Add the prose-cleanup skill (vNext Phase 9)"
- Review status: pending-review
- Discrepancies or follow-up: `prose-cleanup` is a repo-wide writing-quality skill but is registered inside the supervisor orchestration overlay's manifest files for program-pattern continuity; the placement discrepancy is recorded here deliberately. The Phase 7 close-out entry below still carries `pending-review` and awaits independent re-review; only the Phase 8 close-out was flipped to `reviewed` by the architecture gate.

### 2026-09-26 - Close the Phase 8 review follow-up

- Area: agent file
- Change type: docs
- Summary: `.github/agents/delegation-supervisor.agent.md` gains an Approach step naming the `swarm` skill (review finding S1): for independent slices, the supervisor runs the swarm with per-slice write sets and shared-state detection before parallel execution, and aggregates results only after all required slices finish.
- Reason: code review of the Phase 8 slice returned pass-with-follow-ups; the follow-up closes in this change.
- Affected files: .github/agents/delegation-supervisor.agent.md
- Related code: CHANGELOG.md entry "2026-09-26 - Close the Phase 8 review follow-up"
- Review status: reviewed
- Discrepancies or follow-up: none open for this slice; the shared-state-detection and slice-decomposition deferrals stay recorded in the earlier Phase 8 entries.

### 2026-09-26 - Document the swarm skill (vNext Phase 8)

- Area: skills runbook, supervisor runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/skills.md` gains a `swarm` entry under Optional Overlay Skills with example prompts and the ARENA-versus-SWARM differentiation, and the supervisor runbook's behavioral notes now state that a swarm runs different independent slices concurrently, detects shared mutable state before parallel execution, forbids silent overwrites, and aggregates results only after all required slices finish.
- Reason: vNext Phase 8 lands the swarm skill; the docs land in the same change so the skill catalog and the runbook describe the shipped skill and its difference from the arena bakeoff.
- Affected files: docs/runbooks/skills.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-26 - Add the swarm skill (vNext Phase 8)"
- Review status: pending-review
- Discrepancies or follow-up: the runbook sentences are descriptive and unpinned; the contract linkage is pinned by the paired text assertions in the validator twins. The skill is not registered in the module manifest under its own module id, matching the existing pattern of listing overlay skills inside their owning overlay's files.

### 2026-09-26 - Close the Phase 7 review follow-up

- Area: agent file
- Change type: docs
- Summary: `.github/agents/delegation-supervisor.agent.md` gains an Approach step naming the `arena-bakeoff` skill (review finding S1): for decisions where alternative implementations provide meaningful value, the supervisor runs the bakeoff with isolated candidates, selects a base, and synthesizes only compatible improvements.
- Reason: code review of the Phase 7 slice returned pass-with-follow-ups; the follow-up closes in this change.
- Affected files: .github/agents/delegation-supervisor.agent.md
- Related code: CHANGELOG.md entry "2026-09-26 - Close the Phase 7 review follow-up"
- Review status: pending-review
- Discrepancies or follow-up: none open for this slice; the isolation-rule and rubric-pinning deferrals stay recorded in the earlier Phase 7 entries.

### 2026-09-26 - Document the arena-bakeoff skill (vNext Phase 7)

- Area: skills runbook, supervisor runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/skills.md` gains an `arena-bakeoff` entry under Optional Overlay Skills with example prompts, and the supervisor runbook's behavioral notes now state that arena bakeoffs run N isolated candidates with one candidate per worktree, branch, or temporary directory, require the same five returns per candidate, score all candidates against one rubric, synthesize only compatible improvements, and never average incompatible architectures.
- Reason: vNext Phase 7 lands the arena-bakeoff skill; the docs land in the same change so the skill catalog and the runbook describe the shipped skill.
- Affected files: docs/runbooks/skills.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-26 - Add the arena-bakeoff skill (vNext Phase 7)"
- Review status: pending-review
- Discrepancies or follow-up: the runbook sentences are descriptive and unpinned; the contract linkage is pinned by the paired text assertions in the validator twins. The skill is not registered in the module manifest under its own module id, matching the existing pattern of listing overlay skills inside their owning overlay's files.

### 2026-09-26 - Close the Phase 6 review follow-ups

- Area: agent file
- Change type: docs
- Summary: `.github/agents/delegation-supervisor.agent.md` step 6 now names the `adversarial-review` skill (review finding W1). This entry also records review finding W2: the skill's severity vocabulary (`blocker`, `major`, `minor`, `note`) and verdict vocabulary (`BLOCKED`, `CHANGES_REQUIRED`, `PASS_WITH_NOTES`, `CLEAN`) are playbook-local and unpinned, and mapping them to `delegation-result.schema.json`'s `status` vocabulary (`completed`, `partial`, `blocked`, `failed`) is deferred until a phase consumes findings into the result contract.
- Reason: code review of the Phase 6 slice returned pass-with-follow-ups; the two follow-ups close in this change.
- Affected files: .github/agents/delegation-supervisor.agent.md
- Related code: CHANGELOG.md entry "2026-09-26 - Close the Phase 6 review follow-ups"
- Review status: pending-review
- Discrepancies or follow-up: none open for this slice; the vocabulary mapping remains deferred as recorded above.

### 2026-09-26 - Document the adversarial-review skill (vNext Phase 6)

- Area: skills runbook, supervisor runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/skills.md` gains an `adversarial-review` entry under Optional Overlay Skills with example prompts, and the supervisor runbook's behavioral notes now state that adversarial review attempts to prove a change wrong, fixes the six-field finding format, requires reviewers to inspect the actual diff, deduplicates findings, and lets evidence outrank voting.
- Reason: vNext Phase 6 lands the adversarial-review skill; the docs land in the same change so the skill catalog and the runbook describe the shipped skill.
- Affected files: docs/runbooks/skills.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-26 - Add the adversarial-review skill (vNext Phase 6)"
- Review status: pending-review
- Discrepancies or follow-up: the runbook sentences are descriptive and unpinned; the contract linkage is pinned by the paired text assertions in the validator twins. The skill is not registered in the module manifest under its own module id, matching the existing pattern of listing overlay skills inside their owning overlay's files.

### 2026-09-26 - Close the Phase 5 review conditions

- Area: ADR, runbook
- Change type: docs, adr
- Summary: ADR 0006's Follow-up now records that Phase 5 landed on 2026-09-26: `.github/skills/verification-evidence-loop/SKILL.md` emits the contract's `verificationPerformed` entries directly, and both validator twins pin the skill's reference to the schema. The twin-side pin of the skill's INCONCLUSIVE-never-success rule (review condition C2) is documented in the paired code entry.
- Reason: architecture review conditions C1 (ADR amendment recording the Phase 5 landing) and C2 (rule pin), applied after the pass-with-conditions verdict.
- Affected files: docs/adr/0006-delegation-result-contract.md
- Related code: CHANGELOG.md entry "2026-09-26 - Pin the verification skill's INCONCLUSIVE rule in the twins (Phase 5 review condition C2)"
- Review status: pending-review
- Discrepancies or follow-up: none; both review conditions are closed and the Phase 5 slice is fully reviewed.

### 2026-09-26 - Document the verification-evidence-loop skill (vNext Phase 5)

- Area: skills runbook, supervisor runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/skills.md` gains a `verification-evidence-loop` entry under Optional Overlay Skills with example prompts, and the supervisor runbook's Routing section notes that the skill walks the `evidenceRequirements` contract and emits `delegation-result.schema.json`-shaped verification entries.
- Reason: vNext Phase 5 lands the verification skill and ADR 0006's follow-up names it as the emitter of the result contract; the docs land in the same change so the skill catalog and the runbook describe the shipped skill.
- Affected files: docs/runbooks/skills.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-26 - Add the verification-evidence-loop skill (vNext Phase 5)"
- Review status: pending-review
- Discrepancies or follow-up: the skills-runbook entry is descriptive and unpinned; the contract linkage itself is pinned by the paired text assertion in the validator twins. The skill is not registered in the module manifest under its own module id, matching the existing pattern of listing overlay skills inside their owning overlay's files.

### 2026-09-26 - Accept ADR 0006 and add full-validator commands (review condition C1)

- Area: ADR, runbook
- Change type: docs, adr, runbook
- Summary: ADR 0006 moves from `Proposed` to `Accepted` with an `- Approved:` line recording the 2026-09-26 maintainer approval after the architecture review passed with conditions, and rollout step 1 records the trail. The supervisor runbook's full-validator subsection now names both schemas and lists `python -m jsonschema` and `npx ajv-cli` commands for the delegation-result example alongside the delegation-plan pair, closing review condition C1.
- Reason: the architecture review of the Phase 4 slice returned pass-with-conditions; C1 was the documentation condition and the maintainer accepted the ADR on 2026-09-26.
- Affected files: docs/adr/0006-delegation-result-contract.md, docs/runbooks/supervisor-orchestration.md
- Related code: None. Docs-only; the executable contract landed in the CHANGELOG.md entry "2026-09-26 - Add the delegation result contract and pin it with validators (vNext Phase 4)".
- Review status: pending-review
- Discrepancies or follow-up: the earlier DOC entry for ADR 0006 says the ADR is `Proposed` and binds nothing until acceptance; this acceptance supersedes that sentence. Phase 5 (a dedicated verification skill that emits this contract) is now unblocked.

### 2026-09-26 - Record the delegation result contract decision and document it

- Area: ADR, runbook, agent file
- Change type: docs, adr, runbook
- Summary: added `docs/adr/0006-delegation-result-contract.md` as `Proposed`, recording the decision to add `delegation-result.schema.json` and its worked example, to validate the example in both twins, to pin the schema's `agent`, `result`, and `surface` enums against the policy data, and to add the `malformed-delegation-result` negative fixture per platform. The supervisor runbook's Module Files list gains the two new paths, the Validating section names the new checks, and the fixture enumeration moves from forty-five to forty-seven fixtures per platform (forty-three negative plus three positive) with the new case. The supervisor agent file's Required Inputs states that workers return results shaped by the schema and that a structured result is a communication contract, not proof.
- Reason: ADR 0006 Rollout steps 1 and 4. The result contract is a durable decision, so it is recorded before or with its implementation, and the docs land in the same change as the validators so no document describes a contract the checks do not assert.
- Affected files: docs/adr/0006-delegation-result-contract.md, docs/runbooks/supervisor-orchestration.md, .github/agents/delegation-supervisor.agent.md
- Related code: CHANGELOG.md entry "2026-09-26 - Add the delegation result contract and pin it with validators (vNext Phase 4)"
- Review status: pending-review
- Discrepancies or follow-up: ADR 0006 is `Proposed` and binds no repo until architecture review and maintainer acceptance; the implementation landed data-first per the rollout plan, matching the ADR 0005 precedent. ADR 0006 is not registered in `.github/starter-modules.json`, matching the precedent of ADRs 0002, 0004, and 0005. The runbook fixture enumeration remains a documentation-only list that no validator reads.

### 2026-09-23 - Accept ADR 0005 and de-duplicate the routing prose (rollout steps 1 and 4)

- Area: ADR, runbook, agent file
- Change type: docs, adr, runbook
- Summary: ADR 0005 moves from `Proposed` to `Accepted` with an `- Approved:` line recording the 2026-09-23 maintainer approval after the architecture review passed with conditions F1-F4 on 2026-09-14, which the amendment resolved. Rollout step 1 and the Operational impacts sentence record the same trail. The runbook's Simple Versus Complex Routing section no longer restates the eleven criteria or the workflow text: a new Routing section points at `taskClasses`, `playbooks`, `complexityRouting`, and `evidenceRequirements` and keeps only the two behavioral notes that are not data. The Validating section names the new routing-data checks, and the fixture enumeration moves from thirty-two to forty-five fixtures per platform (forty-two negative plus three positive) with the new negative cases. The supervisor agent file's Approach now classifies on both policy axes, follows the selected playbook, and ties completion to `evidenceRequirements` instead of a restated procedure.
- Reason: ADR 0005 Rollout steps 1 and 4. The maintainer accepted the ADR on 2026-09-23, and the de-dup lands in the same change as the validator slice so no document describes routing that the data does not carry.
- Affected files: docs/adr/0005-routing-policy-as-data.md, docs/runbooks/supervisor-orchestration.md, .github/agents/delegation-supervisor.agent.md
- Related code: CHANGELOG.md entry "2026-09-23 - Pin the routing policy data with validator checks and fixtures (ADR 0005 rollout slice 3)"
- Review status: pending-review
- Discrepancies or follow-up: the earlier DOC entry "2026-09-14 - Amend ADR 0005 for the architecture review conditions and record the routing data" says the ADR remains `Proposed`; this acceptance supersedes that sentence. The runbook's fixture enumeration remains a documentation-only list that no validator reads, and the new routing prose is not text-pinned by any assertion; the rules it describes are pinned by the validator checks and fixtures instead.

### 2026-09-14 - Amend ADR 0005 for the architecture review conditions and record the routing data

- Area: ADR, orchestration routing model
- Change type: docs, adr, reference
- Summary: ADR 0005 now answers the four architecture-review conditions in its own text. F1 (classification model): the playbooks bullet states the two-axis relationship — `taskClasses` owns playbook selection, `complexityRouting` owns the simple/complex escalation envelope, and the supervisor records both the class and the complexity verdict. F2 (stage fields): the playbooks bullet states the `delegatesTo` predicate — case-sensitive, allow-listed agent ids or `delegation-supervisor`, with human-approval stages setting `requiresHumanApproval: true` and an empty `delegatesTo`, exactly one of the two per stage. F3 (sequencing): Rollout step 3 now includes the `complexityRouting` pins and the fixture for a stage carrying both fields set. F4 (vocabulary): the `evidenceRequirements` bullet enumerates the closed surface vocabulary and names the completion rule. The ADR remains `Proposed`.
- Reason: the architecture reviewer accepted ADR 0005 on four conditions; the amendments resolve them before the implementation slice that lands the policy data.
- Affected files: docs/adr/0005-routing-policy-as-data.md
- Related code: CHANGELOG.md entry "2026-09-14 - Add routing data to the orchestration policy (ADR 0005 rollout slice 2, data first)"
- Review status: pending-review
- Discrepancies or follow-up: the ADR stays `Proposed` until acceptance; the preceding entry "2026-09-14 - Record the routing-policy-as-data decision in ADR 0005" records the original text this entry amends.

### 2026-09-14 - Record the routing-policy-as-data decision in ADR 0005

- Area: ADR, orchestration routing model
- Change type: docs, adr, reference
- Summary: added `docs/adr/0005-routing-policy-as-data.md` as `Proposed`. It records the decision to add three additive overlay-scoped keys to `orchestration-policy.json` — `taskClasses` (the thirteen-class taxonomy as a closed id vocabulary), `playbooks` (an ordered stage list per class with `delegatesTo` agent names and a per-stage skip-reason obligation), and `evidenceRequirements` (per-surface evidence kinds plus the fixed VERIFIED / NOT_VERIFIED / INCONCLUSIVE vocabulary and the orchestrator-declared completion rule in data form) — and to pin them with validator checks and negative fixtures per platform, while keeping the completion invariant a prompt-level contract. Options Considered records the status quo, a second routing file, full machine enforcement, and the adopted shape.
- Reason: ADR 0004 Phase 6 explicitly deferred the decision of whether task classes, playbooks, and evidence requirements belong in the policy file; its Decision states they do, because a table can be pinned by fixtures and prose cannot. Today `complexityRouting` is data but the taxonomy, playbooks, and evidence vocabulary are prose split across the runbook, the agent file, and the vNext direction, which no check reads.
- Affected files: docs/adr/0005-routing-policy-as-data.md, DOC-CHANGELOG.md
- Related code: None. No executable asset changed in this slice; ADR 0005 describes implementation that has not landed, and the paired `CHANGELOG.md` entries belong to the rollout slices that change the policy file and the validator twins.
- Review status: pending-review
- Discrepancies or follow-up: the ADR is `Proposed` and binds no repo until architecture review and maintainer acceptance. The policy file already carries `complexityRouting`, which the ADR keeps unchanged; the new keys are additive and no existing check reads unknown keys, so landing the data before the validators cannot go red. ADR 0005 is not registered in `.github/starter-modules.json`, matching the precedent of ADRs 0002 and 0004.

### 2026-09-14 - Document the full case-sensitivity normalization and the exact-match contract

- Area: overlay runbook
- Change type: docs, runbook
- Summary: `docs/runbooks/supervisor-orchestration.md` gains one sentence in Supported Runtimes stating that adapter-name matching is exact and case-sensitive, that a case variant such as `EDIT` is a distinct non-mutating host name that cannot collide with the repository's own `edit` tool, and that the same exact-match rule applies to every tool, role, allow-list, and category name the validators compare.
- Reason: the previous slice normalized the adapter-vocabulary comparisons, but the exact-match contract was documented only in the fixture paragraph; adopters reading the host table had no statement of the rule. The sentence lands in the same change as the final case-sensitivity normalization of the PowerShell twin.
- Affected files: docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-14 - Normalize the remaining case-insensitive membership tests in the PowerShell twin"
- Review status: pending-review
- Discrepancies or follow-up: the new sentence is descriptive and unpinned by any text assertion; the exact-match rule is pinned behaviorally by the `adapter-case-variant-tool-name` fixture for the vocabulary scans it exercises.

### 2026-09-14 - Document the matrix adapter-tool fixture pin, the case-variant guard pin, and the ADR follow-up correction

- Area: runbooks, ADR
- Change type: docs, runbook, adr, reference
- Summary: updated `docs/runbooks/supervisor-orchestration.md` so the fixture enumeration reads thirty-two fixtures per platform (twenty-nine negative plus three positive), the negative list names the capability-matrix host-adapter-tool case, and a new sentence records the third positive fixture that pins the case-sensitive adapter-vocabulary treatment. Updated `docs/adr/0004-adapter-bound-delegation.md`: the validation section's negative list gains the matrix adapter-tool case and its positive list gains the case-variant tolerance; the implementation-status paragraph records twenty-nine negative plus three positive fixtures and names both new pins; and the stale follow-up bullet claiming `runSubagent` was unverified is corrected to match the recorded 2026-09-14 verification.
- Reason: the runbook and ADR had drifted from the fixture suite, and the ADR contradicted its own implementation-status paragraph on the host tool verification status.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0004-adapter-bound-delegation.md
- Related code: CHANGELOG.md entry "2026-09-14 - Pin the matrix adapter-tool guard and the case-sensitive adapter vocabulary on both platforms"
- Review status: pending-review
- Discrepancies or follow-up: none

### 2026-09-14 - Document the empty-adapter-list alignment and the second positive fixture

- Area: overlay runbook, ADR
- Change type: docs, adr, runbook
- Summary: `docs/runbooks/supervisor-orchestration.md` moves its fixture enumeration from twenty-nine to thirty fixtures (twenty-eight negative and two positive) and records that the second positive fixture pins the empty-`delegationTools` representation for unsupported hosts. `docs/adr/0004-adapter-bound-delegation.md` corrects its implementation-status sentence to name both additional negative fixtures and two positive fixtures, and its Validation sentence now covers the empty-list acceptance alongside the shipped-tree and tolerated-state acceptances.
- Reason: the code review found the ADR status sentence undercounted the extra fixtures and that the empty-list representation was unmentioned in the validation list; the docs were updated in the same change as the fix.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0004-adapter-bound-delegation.md
- Related code: CHANGELOG.md entry "2026-09-14 - Align the adapter-map shape check across platforms and pin the empty-list host representation"
- Review status: pending-review
- Discrepancies or follow-up: the runbook fixture enumeration remains a documentation-only list that no validator reads; the two positive fixtures are pinned by the harness instead. No new text assertions were added for these sentences.

### 2026-09-14 - Document the closed registration direction

- Area: overlay runbook, ADRs
- Change type: docs, adr, runbook
- Summary: `docs/runbooks/supervisor-orchestration.md` replaces the "One boundary remains" paragraph with a statement that registration is now checked in both directions: every agent file not on the specialist allow-list must carry an `agentCapabilityMatrix` entry and an `agentRoleHints` entry, and the tolerance for an allow-listed non-mutating agent with no matrix entry stays because the tier derives from frontmatter. The fixture enumeration moves from twenty-seven to twenty-nine (twenty-eight negative plus one positive) with the two new cases named. `docs/adr/0003-supervisor-orchestration-overlay.md` gains a second amendment bullet and extends the Follow-up amendment line with the Phase 3 landing. `docs/adr/0004-adapter-bound-delegation.md` updates its implementation status: Phases 1, 2, 3, and 5 have landed with all six Phase 4 fixtures plus one additional fixture per platform, and the remaining open item is the unpinned matrix-adapter branch from Phase 2.
- Reason: the registration rule is now enforced in the paired validators, so the design documents must describe it rather than continue claiming the direction is open, which is the drift class the runbook's fixture paragraph warns about.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md, docs/adr/0004-adapter-bound-delegation.md
- Related code: CHANGELOG.md entry "2026-09-14 - Close the registration direction for non-allow-listed agents"
- Review status: pending-review
- Discrepancies or follow-up: the new rule-description sentences are pinned by paired text assertions (`must carry an `agentCapabilityMatrix` entry` in the runbook and `Amended by ADR 0004 Phase 3` in ADR 0003); the remaining new prose, including the fixture case list, is descriptive and unpinned. The runbook's fixture enumeration remains a documentation-only list that no validator reads.

### 2026-09-14 - Document the adapter-bound delegation capability change

- Area: overlay runbook, ADRs
- Change type: docs, adr, runbook, policy
- Summary: `docs/runbooks/supervisor-orchestration.md` replaces the vague "Other runtimes" delegation mapping with a host table sourced from `delegationDepth.hostAdapters` in `orchestration-policy.json` and records the verification dates for `agent`/`runSubagent` (VS Code) and `agent` with aliases `custom-agent`/`Task` (GitHub Copilot CLI/cloud). The Validating section now states that the platform vocabulary is derived from the map, that the map is checked for shape and mutating names, that the supervisor frontmatter is held to the closed set, that the two pairing rules replace the blanket ban, and that the capability matrix must not enable host tool names. The stale coordinator sentence is corrected: `orchestration-coordinator` has been registered under the `advisory` role since Phase 1 and is no longer an instance of the tolerated unregistered state; the tolerance itself remains, with ADR 0004 Phase 3 recorded as the unimplemented rule that would close the reverse direction. The fixture enumeration moves from twenty-three to twenty-seven (twenty-six negative plus one positive) with the four new cases named. `docs/adr/0003-supervisor-orchestration-overlay.md` gains an amendment bullet in Decision and an amendment line in Follow-up recording the rule-shape change, and `docs/adr/0004-adapter-bound-delegation.md` updates its implementation status: Phases 1, 2, and 5 landed with five of the six Phase 4 fixtures, and Phase 3 plus the sixth fixture remain open.
- Reason: ADR 0004's Operational impacts require the runbook and the ADR 0003 amendment pointer to land in the same change as the implementation, so no design document describes a rule the code does not assert. The runbook also still described the coordinator as an unregistered role-model exception after Phase 1 closed exactly that state.
- Affected files: docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md, docs/adr/0004-adapter-bound-delegation.md
- Related code: CHANGELOG.md entry "2026-09-14 - Bind the delegation capability to host tool names and close the inert-delegation defect"
- Review status: pending-review
- Discrepancies or follow-up: two new sentences are pinned by paired text assertions (`hostAdapters` in the runbook and `Amended by ADR 0004` in ADR 0003); the remaining new prose, including the host table, the verification dates, and the fixture case list, is descriptive and unpinned, so it can drift without a failing check. The host names inside `orchestration-policy.json` are themselves unpinned by any validator. The runbook's fixture enumeration remains a documentation-only list that no validator reads.

### 2026-09-14 - Accept ADR 0004 and correct its role-vocabulary premise

- Area: ADR, agent catalog, role registry documentation
- Change type: docs, adr, policy
- Summary: `docs/adr/0004-adapter-bound-delegation.md` moves from `Proposed` to `Accepted` with an `- Approved:` line recording the 2026-09-14 maintainer approval for the `core-governance-change`. Its Context no longer claims that no role in `tool-access.json` carries the coordinator's tool set: the `review` role carries exactly `read`, `search`, and `todo`, so a slot with matching capabilities does exist, and the corrected text argues from the role's stated purpose instead. The paragraph now names `review` as the near-miss, describes what registering the coordinator under it would misstate, and records that the earlier claim was made after comparing only `analysis` and `workflow-maintenance`. The corresponding option in Options Considered was rewritten from "register under an existing role" to the concrete `review` alternative with its corrected cons. The Follow-up implementation-status line now records that Phase 1 has landed and that Phases 2 to 5 have not, and states which of the two defects the ADR corrects is closed. `.github/AGENTS.md` aligns the coordinator's role string to the vocabulary (`advisory`) and adds one sentence stating that the agent recommends a transition for human approval and never invokes another agent itself.
- Reason: the ADR was approved on the strength of a premise that turned out to be false. The original Context asserted that the coordinator's declaration "matches no role in `tool-access.json`" and supported that with two roles; `review` was not checked and matches exactly. The decision is unchanged, because it rests on the purpose a role records rather than on whether a role with the same capabilities exists, but the reasoning had to be corrected before Phase 1 was implemented rather than left standing. `AGENTS.md` was changed in the same slice because a role string outside the vocabulary is the same class of registry defect the phase exists to close.
- Affected files: docs/adr/0004-adapter-bound-delegation.md, .github/AGENTS.md
- Related code: CHANGELOG.md entry "2026-09-14 - Register the orchestration coordinator and add the advisory role"
- Review status: pending-review
- Discrepancies or follow-up: the correction was applied to the ADR text in place rather than through a superseding ADR, because the ADR had been accepted hours earlier and no implementation had landed against the false premise; the change is recorded here so the substitution is traceable rather than silent. The ADR's underlying claim about `review` is verified by reading `tool-access.json`, not asserted from memory. ADR 0004 is not registered in `.github/starter-modules.json`, matching the precedent of `docs/adr/0002-game-asset-storage-policy.md`, so the manifest's ADR inventory remains incomplete and no check enforces it. Phases 2 to 5 of the rollout remain unimplemented, including the host adapter map, the pairing rules, and the registration rule for non-allow-listed agents, so the inert-delegation defect ADR 0004 describes is still present in the shipped validator. The `delegation-supervisor` still declares no host delegation tool and no `agents` allow-list.

### 2026-09-14 - Record the adapter-bound delegation decision in ADR 0004

- Area: ADR, orchestration capability model
- Change type: docs, adr, policy, reference
- Summary: added `docs/adr/0004-adapter-bound-delegation.md` as `Proposed`. It records the decision to bind the abstract `delegate-agent` capability to each host's real delegation tool through a `hostAdapters` map in `.github/roles/orchestration-policy.json`, to replace exact tool-set equality in both supervisor orchestration validator twins with contains-plus-closed-adapter-allow-list, to add the pairing rules (`agents` requires the host tool and the host tool requires `agents`), to add an `advisory` role holding `read`, `search`, and `todo` so `orchestration-coordinator` can be registered truthfully, and to require a capability-matrix entry and a role hint for every agent file that is not on the specialist allow-list. It classifies `handoffs` as the host's human-driven guided-transition mechanism rather than a delegation path, keeps routing policy as data, and records that the two orchestration agents are not merged and that no core orchestrator is created. Options Considered records the eight alternatives, including status quo, host-native-only declaration, per-host agent files, a script-driven invoker, consolidating the two agents, and registering the coordinator under an existing role.
- Reason: an independent architecture review of the delegation capability model returned `pass-with-conditions` on the direction. The strongest argument it produced is a contradiction inside the repository rather than a gap: `tool-access.json` v1.2 already documents `delegate-agent` as "platform-mapped, not a literal tool name," while `check-supervisor-orchestration.sh` fixes the tool set by exact equality so no agent file can declare that mapping. The shipped supervisor therefore holds a capability it cannot exercise, and neither the dead-declaration case (`agents` with no host tool) nor the unscoped case (host tool with no `agents`) is guarded. The same review found `orchestration-coordinator` registered in the agent catalog and the module manifest but absent from the capability matrix and the role hints, which nothing detects because the matrix scan iterates the matrix rather than the agent files. The review's proposed registration rule was scoped to delegation-capable agents, which would not have caught the coordinator at all; the ADR replaces it with a scope derived from why the tolerance exists, since the tolerated state is only safe for allow-listed agents whose tier is derived from frontmatter.
- Affected files: docs/adr/0004-adapter-bound-delegation.md, DOC-CHANGELOG.md
- Related code: None. No executable asset changed in this slice; ADR 0004 describes implementation that has not landed, and the paired `CHANGELOG.md` entries belong to the rollout slices that change the validator twins and the two approval-protected governance files.
- Review status: pending-review
- Discrepancies or follow-up: the ADR is `Proposed` and binds no repo until a maintainer accepts it, and the change it describes is a `core-governance-change` because it edits `.github/AGENTS.md` and `.github/roles/tool-access.json`. ADR 0003 is `Accepted` and was deliberately not edited; its amendment pointer is deferred to the change that lands the implementation with its recorded approval. `check-markdown-quality.sh` has not been run against the new file, which carries no local Markdown links and no trailing whitespace by inspection, and neither workflow entry point has been executed for this slice. ADR 0004 is not registered in `.github/starter-modules.json`, matching the precedent of `docs/adr/0002-game-asset-storage-policy.md`, which is also unlisted, so the manifest's ADR inventory remains incomplete and is not enforced by any check. Two further repo-truth items observed while gathering evidence for the review are unchanged by this slice: the top `CHANGELOG.md` entry for the block-form frontmatter change still reads `Validation: Not run` while the session's terminal history shows `check-starter-workflow.sh` and `check-supervisor-orchestration.ps1` both exiting 0, so one of the two is stale; and the `orchestration-coordinator` registration decision, NB-2, NB-3, and the SEC findings remain open.

### 2026-09-14 - Record block-form frontmatter support in ADR 0003 and the supervisor runbook

- Area: overlay ADR, runbooks
- Change type: docs, policy, reference
- Summary: ADR 0003's Decision section and the supervisor overlay runbook's sole-holder paragraph now state that both `tools` and `agents` are read in the inline array form and in the block list form, so reformatting a declaration cannot move it outside the scan. The ADR's Validation section notes that the platform-delegation and allow-list cases cover both forms. The runbook's fixture enumeration is corrected from twenty-one fixtures (twenty negative and one positive) to twenty-three (twenty-two negative and one positive), with the two block-form cases added to the case list.
- Reason: the paired validators were extended in the same change to parse block lists, and both documents describe what those validators assert. Leaving them unedited would have left the design documents claiming narrower coverage than the code provides, which is the drift class the runbook's own fixture paragraph warns about and the same reason the previous entry in this pair was written.
- Affected files: docs/adr/0003-supervisor-orchestration-overlay.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-14 - Read block-style frontmatter in the supervisor sole-holder scan"
- Review status: pending-review
- Discrepancies or follow-up: neither document was executed against; `check-markdown-quality.sh` and the paired overlay validators still need to run, since Markdown quality scans these files for trailing whitespace and broken local links. The new sentences are descriptive rather than load-bearing and are not pinned by `assert_file_contains`, so they can drift silently; the rules they describe are pinned by the fixtures instead. The fixture count and case list in the runbook remain a documentation-only list that no validator reads.

### 2026-09-14 - Record the extended sole-holder invariant in ADR 0003 and the supervisor runbook

- Area: overlay ADR, runbooks
- Change type: docs, policy, reference
- Summary: `docs/adr/0003-supervisor-orchestration-overlay.md` now states in its Decision section that the sole-holder restriction applies over the host's own delegation vocabulary, not only over the repository's abstract `delegate-agent` capability: an agent file other than `delegation-supervisor` may not declare a platform delegation tool in its `tools` list or declare an `agents` allow-list, and a supervisor `agents` allow-list must stay within the canonical `specialistAllowList`. The ADR's Validation section enumerates the three new negative-fixture cases. `docs/runbooks/supervisor-orchestration.md` describes the same rule in its sole-holder paragraph, and its fixture enumeration is corrected from eighteen fixtures (seventeen negative and one positive) to twenty-one (twenty negative and one positive), with the three new cases named in the case list.
- Reason: the paired validators were extended in the same change, and both the ADR and the runbook describe what those validators assert. Leaving them unedited would have left the design documents claiming a narrower rule than the code enforces, which is the drift class the runbook's own fixture paragraph warns about.
- Affected files: docs/adr/0003-supervisor-orchestration-overlay.md, docs/runbooks/supervisor-orchestration.md
- Related code: CHANGELOG.md entry "2026-09-14 - Close the platform-vocabulary gap in the supervisor sole-holder invariant"
- Review status: pending-review
- Discrepancies or follow-up: `check-markdown-quality.sh` ran green against these edits as part of the ten-check umbrella run recorded in the related `CHANGELOG.md` entry, so the edited documents carry no trailing whitespace or broken local links, and the overlay validator's text assertions on both files still pass. The extended rule is pinned by the three new negative fixtures rather than by new `assert_file_contains` text assertions, so the ADR and runbook sentences describing it are unpinned in the sense that no check reads them. The fixture count and case list in the runbook remain a documentation-only list that no validator reads, so that drift class still applies.

### 2026-09-14 - Correct the VS Code handoff and subagent rows in the tool-surface matrix

- Area: runbooks, architecture reference, overlay ADR
- Change type: docs, policy, reference
- Summary: `docs/runbooks/tool-surface-matrix.md` no longer understates VS Code. The `Handoffs` row changes the VS Code column from `Repo convention` to `Direct` and names the supported sub-fields (`label`, `agent`, `prompt`, `send`); the `Delegate subagent` row now names the `agent` tool plus an `agents:` allow-list and records that nested delegation is off by default. Six Platform Notes bullets were added under `GitHub Copilot VS Code Agent Mode` covering the `handoffs` and `agents` verification with its revision date; the nesting default, `chat.subagents.allowInvocationsFromSubagents`, `disable-model-invocation`, and `user-invocable`; agent-scoped `hooks` being Preview behind `chat.useCustomAgentHooks`; subagent statelessness and the absence of todo and clarifying-question tools; host-level approval controls; and the deliberate omission of `model` and `handoffs.model`. `docs/runbooks/supervisor-orchestration.md` now names the concrete VS Code mechanism and adds a probe procedure for the hook-inheritance precondition: enable a `PreToolUse` hook that records its invocation, delegate one read-only task to a non-mutating tier member, and check `.github/hooks/logs/agent-audit.log` between the `SubagentStart` and `SubagentStop` events. `docs/adr/0003-supervisor-orchestration-overlay.md` scopes the non-mutating tier's `todo` entry: `todo` is not a mutating capability and is unavailable in subagent context, so the withholding property rests on the absence of `edit` and `execute`.
- Reason: the VS Code custom-agents and hooks documentation was read directly to settle the host-capability question that blocked the orchestration vNext review. It confirms `handoffs` and `agents` as documented frontmatter, which makes the matrix's `Repo convention` entry for VS Code incorrect, and it adds `SubagentStart` and `SubagentStop` events that the hook-inheritance precondition did not previously have a probe method for. The tier predicate's inclusion of `todo` was a latent inaccuracy that no check could catch: the tier in the shipped allow-list is `architecture-reviewer`, `code-reviewer`, and `security-reviewer`, and each declares `todo` in both its frontmatter and its `agentCapabilityMatrix` entry.
- Affected files: docs/runbooks/tool-surface-matrix.md, docs/runbooks/supervisor-orchestration.md, docs/adr/0003-supervisor-orchestration-overlay.md
- Related code: None
- Review status: pending-review
- Discrepancies or follow-up: validation is static verification only. No terminal tool was available in this session, so `check-markdown-quality.sh` and both workflow entry points were not executed; the edits were verified by inspection and contain no trailing whitespace or new local links. The Copilot CLI cell for `Delegate subagent` stays `Unsupported` because GitHub's documentation was not read, so that claim remains an unverified omission rather than a checked fact. The governance gap this review identified is deliberately not addressed here: `check-supervisor-orchestration.sh` and its PowerShell twin match the literal capability name `delegate-agent`, while the platform expresses delegation as the `agent` tool and an `agents:` frontmatter key, neither of which any check inspects. Closing that gap is a `core-governance-change` requiring both validator twins, new negative fixtures per platform, and a recorded approval. The matrix rows and the runbook's runtime-mapping paragraph remain unpinned by any validator, so they can drift again silently.

### 2026-09-14 - Document the game overlay registration and version-matched Phaser overlays

- Area: runbooks, architecture reference
- Change type: docs, runbook, reference
- Summary: recorded the two game overlays that were previously unregistered. `docs/runbooks/game-dev.md` now states that Phaser and Go game toolkits are the supported engine overlays, requires exactly one version-matched Phaser overlay rather than both, and replaces the open "Phaser-only or siblings" decision with the current sibling set. `docs/runbooks/starter-composition.md` mirrors the one-Phaser-overlay rule and adds the Go overlay, and `docs/runbooks/adopting-existing-github.md` extends its game overlay row the same way. `docs/ARCHITECTURE.md` gains the `overlay-game-go` node and its edge to `overlay-game-core`.
- Reason: `.github/instructions/js.phaser4.instructions.md` and `.github/instructions/go.gamedev.instructions.md` were populated and are now registered in `.github/starter-modules.json`, but the documents that tell an adopter which overlays to compose did not mention them. The two Phaser overlays declare an identical `applyTo` scope, so leaving the choice implicit would have let an adopter enable both and attach two engine overlays to the same files.
- Affected files: docs/ARCHITECTURE.md, docs/runbooks/game-dev.md, docs/runbooks/starter-composition.md, docs/runbooks/adopting-existing-github.md
- Related code: CHANGELOG.md entry "2026-09-14 - Close Tier 1 starter debt: eval coverage, game overlay registration, and local-state ignores"
- Review status: pending-review
- Discrepancies or follow-up: the engine overlay eval tasks still name the overlay generically, for example `.github/instructions/phaser.instructions.md`, so no eval pins the version-matched Phaser choice or the Go overlay. Neither workflow entry point was executed in this session, so Markdown link and whitespace integrity for the four edited documents is unverified until the checks run. `docs/adr/0002-game-asset-storage-policy.md` remains `Proposed`. The `orchestration-coordinator` registration decision and the remaining Tier 2 items are still open.

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
