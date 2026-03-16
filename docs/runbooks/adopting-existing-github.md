# Adopting The Starter In A Repo With An Existing .github Folder

This runbook explains how to add this starter to an existing repository that already has a populated `.github` folder.

The main rule is simple: merge selectively, do not replace `.github` wholesale.

## 1. Goals

- Keep existing project context and workflows intact.
- Add the starter baseline in small, reversible steps.
- Avoid hidden behavior changes from optional overlays.
- Treat sample file names as illustrative only; real target repos may have different or missing files.

## 2. Minimal-First Scope

Start with these baseline assets only:

- `.github/copilot-instructions.md`
- `.github/instructions/core.instructions.md`
- `.github/instructions/security.instructions.md`
- `.github/starter-modules.json`
- `CHANGELOG.md`
- `DOC-CHANGELOG.md`

Defer overlays, specialist agents, and hooks until baseline behavior is stable.

## 2.1 Artifact Checklist (Required vs Optional vs Sample-Only)

Use this table during discovery so you can map by purpose even when target file names differ.

| Category | Status | Starter target | What it means | If missing in target repo |
| --- | --- | --- | --- | --- |
| Baseline orchestrator | Required | `.github/copilot-instructions.md` | Top-level guidance that points to baseline rules and source-of-truth docs | Create it and reference real project docs, not starter examples |
| Core baseline rules | Required | `.github/instructions/core.instructions.md` | Delivery and collaboration defaults across all files | Add file as-is, then tune only if repo conventions require it |
| Security baseline rules | Required | `.github/instructions/security.instructions.md` | OWASP-aligned safety defaults and secret-handling constraints | Add file as-is before enabling overlays |
| Module registry | Required | `.github/starter-modules.json` | Source of truth for enabled core/overlay assets | Add minimal-first manifest and keep overlays disabled initially |
| Implementation changelog | Required | `CHANGELOG.md` | Track executable and behavior-affecting changes | Create or map existing equivalent and document naming decision |
| Documentation changelog | Required | `DOC-CHANGELOG.md` | Track runbook/doc/policy updates separately from code | Create or map existing equivalent and document naming decision |
| Frontend overlay | Optional | `.github/instructions/frontend.instructions.md` | UI/JS/TS conventions for repos that need them | Skip until repo has matching frontend code |
| Backend overlay | Optional | `.github/instructions/backend.instructions.md` | Python/SQL backend conventions for repos that need them | Skip until repo has matching backend assets |
| Specialist agents | Optional | `.github/agents/*.agent.md` | Role-specific workflows beyond baseline implementation | Add in follow-up PRs only when active team usage is expected |
| Skills catalog | Optional | `.github/skills/*/SKILL.md` | Reusable playbooks for repeated workflows | Add incrementally based on repeated needs |
| Hook policy and scripts | Optional | `.github/hooks/*` | Command guardrails and audit hooks | Defer until policy owners review impact |
| Sample project docs | Sample-only | `.github/<project-docs>/*` | Example source-of-truth artifacts used to demonstrate mapping | Never require exact names; map to equivalent docs by purpose |

## 3. Pre-Merge Inventory

Create a quick file map before copying anything.

PowerShell:

```powershell
Get-ChildItem .github -Recurse -File | ForEach-Object { $_.FullName }
```

Shell:

```bash
find .github -type f
```

Classify each file into one of these buckets:

- Keep: project-specific docs, contracts, workflows, or configs with no starter equivalent.
- Merge: files with the same path and overlapping intent.
- Add: starter files that do not exist yet.

## 4. Handle The Main Collision First

The common collision is `.github/copilot-instructions.md`.

Use this merge strategy:

1. Keep project-specific constraints and source-of-truth references.
2. Keep the starter baseline rules and security posture.
3. Convert the file into a lightweight orchestrator that points to instruction overlays and real project docs.
4. Avoid copying example references from this starter into production repos.

## 5. Merge Sequence

1. Add baseline instruction files (`core` and `security`) under `.github/instructions/`.
2. Add `.github/starter-modules.json` and keep optional overlays disabled by default.
3. Add or align `CHANGELOG.md` and `DOC-CHANGELOG.md` for split tracking.
4. Update `docs/runbooks/starter-composition.md` references if local paths differ.
5. Commit as one focused baseline PR.

## 6. Validation

Run the local checks after merge:

PowerShell:

```powershell
.github/scripts/check-starter-workflow.ps1
```

Shell:

```bash
.github/scripts/check-starter-workflow.sh
```

Then run a quick smoke test in agent mode:

- Ask for a coding change and confirm core instructions are applied.
- Ask for a security-sensitive change and confirm security instructions are applied.

## 7. Add Optional Modules In Follow-Up PRs

After baseline validation:

1. Add frontend overlay only if JS/TS UI code exists.
2. Add backend overlay only if Python or SQL assets exist.
3. Add specialist agents and skills only when the team will actively use them.
4. Add hooks and policy enforcement only after policy review.

## 8. Mapping Example: existing `.github` project docs (Illustrative Only)

The sample folder is a demonstration of merge patterns, not a required file checklist.
Future target repositories may have different paths, different naming, or no equivalent files.

Map by purpose instead of exact filename:

- Product and architecture context: PRD, stack, design docs, API contracts
- Agent guidance: copilot instructions and instruction overlays
- Governance: changelog strategy and module manifest

Use this example pattern to rehearse merges:

- Existing project context to keep:
  - `.github/prd.md`
  - `.github/stack.md`
  - `.github/fe-design-brief.md`
  - `.github/openapi.local.json`
- Existing file to merge carefully:
  - `.github/copilot-instructions.md`
- Existing changelog pattern to align:
  - `.github/changelog.md` or root `CHANGELOG.md`

Recommended baseline outcome for this pattern:

- Keep project docs as source-of-truth inputs.
- Introduce starter baseline instruction files under `.github/instructions/`.
- Keep optional overlays disabled until target code paths are confirmed.
- Align changelog naming intentionally (`changelog.md` vs `CHANGELOG.md`) and document the decision.

If a target repo does not have equivalent files, continue with the minimal baseline and document assumptions in the PR description.