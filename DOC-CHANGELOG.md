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

### 2026-03-09 - Initialize documentation changelog

- Area: repository governance
- Change type: docs
- Summary: added a dedicated documentation changelog for tracking Markdown and text updates separately from source changes.
- Reason: make doc updates traceable and easier to cross-reference against implementation changes.
- Affected files: DOC-CHANGELOG.md
- Related code: CHANGELOG.md entry "2026-03-09 - Initialize source code changelog"
- Review status: reviewed
- Discrepancies or follow-up: none
