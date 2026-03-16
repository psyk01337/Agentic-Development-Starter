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

### 2026-03-16 - Add existing-.github adoption runbook to governance manifest

- Area: starter governance
- Change type: config
- Summary: updated the starter module manifest to include the new runbook for adopting this starter into repositories that already have a populated `.github` folder.
- Reason: make minimal-first existing-repo migration guidance part of core governance assets and keep manifest/file checks aligned.
- Affected files: .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-03-16 - Add existing-.github adoption runbook and wiring"
- Validation: pending manual check script run
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
