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
