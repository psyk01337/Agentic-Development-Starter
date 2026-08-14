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

### 2026-08-08 - Add LTS-first and documentation-driven dependency rules across instructions

- Area: starter instructions, core, security, backend, frontend
- Change type: enhancement
- Summary: added a "Dependencies and Documentation" section to `core.instructions.md` mandating latest stable LTS releases, official documentation consultation, citation of references, and verification against current docs (not memory or AI-generated examples); added LTS preference, CVE/advisory checking, and docs-consultation rules to `security.instructions.md` Secure Configuration and Supply Chain section; expanded `backend.instructions.md` Dependency and Runtime Hygiene with LTS Python/library guidance and documentation-first rules; added a new "Dependencies" section to `frontend.instructions.md` with LTS Node.js, official docs consultation, citation of references, and advisory-checking rules.
- Reason: establish a cross-cutting rule that agents must always prefer latest stable LTS versions, consult official documentation (not memory or outdated sources), cite references, and check for advisories before using any dependency — applied consistently across core, security, backend, and frontend layers.
- Affected files: .github/instructions/core.instructions.md, .github/instructions/security.instructions.md, .github/instructions/backend.instructions.md, .github/instructions/frontend.instructions.md
- Related docs: DOC-CHANGELOG.md entry "2026-08-08 - Document LTS-first and documentation-driven dependency rules"
- Validation: pending
- Discrepancies or follow-up: none

### 2026-08-08 - Improve instruction file coverage and cross-references

- Area: starter instructions, security, frontend, memory
- Change type: enhancement
- Summary: added a missing intro paragraph to `security.instructions.md` describing its role as the always-applied security baseline; added an "Error Handling" section to `frontend.instructions.md` covering error boundaries, console hygiene, and structured error states (previously absent); split the single "Quality" section in `frontend.instructions.md` into dedicated "Testing" and "Accessibility" sections for parity with the React overlay's structure; added a cross-reference from `core.instructions.md` Safety section to `security.instructions.md` making the layering explicit; added a cross-reference from `honcho-memory.instructions.md` to `memory.instructions.md` for the three-layer memory model.
- Reason: audit of all 12 instruction files found gaps: no intro on security instructions, no error handling guidance for frontend, mixed concerns in frontend Quality section, and missing cross-references that would help agents navigate the layered instruction model.
- Affected files: .github/instructions/security.instructions.md, .github/instructions/frontend.instructions.md, .github/instructions/core.instructions.md, .github/instructions/honcho-memory.instructions.md
- Related docs: DOC-CHANGELOG.md entry "2026-08-08 - Document instruction file improvements"
- Validation: pending
- Discrepancies or follow-up: none

### 2026-07-25 - Document clone-as-template adoption path and initialize-new-project prompt

- Area: starter workflow, runbooks, onboarding, prompts
- Change type: docs, feature
- Summary: added a "Clone-As-Template (New Project Quickstart)" section to `starter-adoption.md` documenting the clone→rename→cleanup→add-app-code adoption path as a first-class alternative to copying `.github/` into an existing repo; added `app/` directory convention for application code separation; added a first-prompt step describing how to use the new `initialize-new-project` prompt to adapt all starter documentation (README, changelogs, overlays) to a specific project's name, tech stack, and goals; created `.github/prompts/initialize-new-project.prompt.md` as a reusable prompt for project initialization; registered the new prompt in `starter-modules.json`; updated `QUICKSTART.md` alternative-path note.
- Reason: users reported that cloning the starter directly and renaming it is their preferred workflow, but this path was undocumented; after cloning, users need a guided way to adapt all documentation to their specific project.
- Affected files: docs/runbooks/starter-adoption.md, QUICKSTART.md, .github/prompts/initialize-new-project.prompt.md, .github/starter-modules.json
- Related docs: DOC-CHANGELOG.md entry "2026-07-25 - Document clone-as-template adoption path and initialize-new-project prompt"
- Validation: pending
- Discrepancies or follow-up: none

### 2026-07-18 - Enrich problem-structuring skill with McKinsey Mind book insights

- Area: starter workflow, skills, evals
- Change type: enhancement
- Summary: enriched the `problem-structuring` skill with concepts from *The McKinsey Mind* (Rasiel & Friga): added Core Principles section (fact-based hypothesis-driven discipline, intuition-data balance with classification, one-day answer, key drivers); strengthened Step 1 (Frame the Problem) with initial hypothesis formation and business need identification; added key-driver focus to Steps 2-3; renamed Step 4 to "Design the Analysis" with confirm/refute framing, dependencies, and fallbacks; split Step 5 into "Gather the Data" and "Interpret the Results" with evidence classification and "so what?" test; expanded Step 7 (Synthesize and Communicate) with buy-in guidance and explicit decision ask; updated eval checklist and task to match enriched output format; updated the `structure-technical-problem` prompt with new deliverables and safety boundaries.
- Reason: incorporate deeper problem-solving rigor from the McKinsey Mind framework — initial hypothesis before decomposition, intuition-data balance, key-driver focus, distinct design-gather-interpret phases, and buy-in considerations.
- Affected files: .github/skills/problem-structuring/SKILL.md, .github/prompts/structure-technical-problem.prompt.md, evals/tasks/problem-structuring.md, evals/expected/problem-structuring.checklist.md
- Related docs: DOC-CHANGELOG.md entry "2026-07-18 - Document problem-structuring enrichment from McKinsey Mind"
- Validation: pending
- Discrepancies or follow-up: none

### 2026-07-17 - Add McKinsey problem-structuring skill, prompt, and evals

- Area: starter workflow, skills, prompts, eval harness
- Change type: feature
- Summary: created the `problem-structuring` skill adapting McKinsey's 7-step problem-solving method (MECE decomposition, hypothesis-driven analysis, issue prioritization, Pyramid Principle synthesis, SCQA communication) for technical contexts; created the `structure-technical-problem` prompt for direct invocation; added eval task and expected checklist for problem-structuring behavior; updated eval runner scripts to include the new task and checklist; enhanced `analyst` and `tech-planner` agent definitions to reference the new frameworks; registered new skill, prompt, and eval assets in `starter-modules.json`.
- Reason: add structured problem-decomposition discipline to bridge the `analyst` → `tech-planner` chain for complex or ambiguous technical problems.
- Affected files: .github/skills/problem-structuring/SKILL.md, .github/prompts/structure-technical-problem.prompt.md, .github/agents/analyst.agent.md, .github/agents/tech-planner.agent.md, .github/starter-modules.json, evals/tasks/problem-structuring.md, evals/expected/problem-structuring.checklist.md, evals/run-evals.sh, evals/run-evals.ps1
- Related docs: DOC-CHANGELOG.md entry "2026-07-17 - Add problem-structuring skill, prompt, and agent enhancements"
- Validation: pending
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
