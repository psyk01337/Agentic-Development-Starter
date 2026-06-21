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

### 2026-06-20 - Complete high-priority documentation

- Area: migration, examples, architecture, module versioning
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
