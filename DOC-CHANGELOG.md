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
