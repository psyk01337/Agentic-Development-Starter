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
