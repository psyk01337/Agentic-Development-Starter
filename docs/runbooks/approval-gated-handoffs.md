# Approval-Gated Handoffs Runbook

This runbook describes the optional orchestration overlay for teams that later want approval-gated auto-handoffs without changing the core guided-handoff model.

## Purpose

This overlay exists for repos that need more structure around agent transitions while still preserving human approval and auditability.

Core behavior does not change:

- One main chat remains the orchestrator.
- Guided handoffs remain the baseline.
- Hidden automatic chains remain excluded from core.

The overlay only adds a richer, approval-gated transition contract for repos that explicitly opt in.

## Module Files

- `.github/agents/orchestration-coordinator.agent.md`
- `.github/skills/approval-gated-handoffs/SKILL.md`
- `.github/schema/approval-gated-handoff-envelope.schema.json`
- `.github/examples/approval-gated-handoffs/approved-tech-planner-to-senior-software-engineer.json`
- `.github/examples/approval-gated-handoffs/pending-architecture-reviewer-to-senior-software-engineer.json`
- `.github/examples/approval-gated-handoffs/rejected-qa-to-senior-software-engineer.json`
- `.github/examples/approval-gated-handoffs/stale-analyst-to-tech-planner.json`
- `.github/scripts/check-approval-gated-orchestration.ps1`
- `.github/scripts/check-approval-gated-orchestration.sh`
- `docs/runbooks/approval-gated-handoffs.md`

Add the overlay through `.github/starter-modules.json` and keep it default-disabled unless the target repo has a real need for it.

## Overlay Contract

The core guided handoff contract is still required. The orchestration overlay extends it with transition metadata:

- `current agent`
- `recommended next agent`
- `scope summary`
- `reason for handoff`
- `approval required`
- `approval status`
- `approver identity`
- `approval timestamp`
- `transition status`
- `audit reference`

These fields are workflow metadata. They are not security-grade authorization unless a future repo-specific enforcement layer adds a trusted identity source and a validated enforcement point.

## Machine-Readable Contract

The overlay transition envelope is defined in `.github/schema/approval-gated-handoff-envelope.schema.json`.

Use that schema when:

- generating transition metadata for future tooling
- validating that overlay-specific handoff fields stay stable
- documenting examples in agents, skills, or runbooks

The schema is intentionally additive to the baseline guided handoff contract. Repos that do not enable this overlay do not need to adopt the richer transition envelope.

## Example Envelopes

Two example transition envelopes are included for tooling and documentation work:

- `.github/examples/approval-gated-handoffs/approved-tech-planner-to-senior-software-engineer.json`
- `.github/examples/approval-gated-handoffs/pending-architecture-reviewer-to-senior-software-engineer.json`
- `.github/examples/approval-gated-handoffs/rejected-qa-to-senior-software-engineer.json`
- `.github/examples/approval-gated-handoffs/stale-analyst-to-tech-planner.json`

Use them as starter fixtures when validating the schema or when building future tooling around approval-gated transitions.

## Validating Example Envelopes

Use any Draft 2020-12 compatible JSON Schema validator against `.github/schema/approval-gated-handoff-envelope.schema.json`.

Optional examples, if your repo already uses these tools:

- Python: `python -m jsonschema -i .github/examples/approval-gated-handoffs/approved-tech-planner-to-senior-software-engineer.json .github/schema/approval-gated-handoff-envelope.schema.json`
- Node: `npx ajv-cli validate -s .github/schema/approval-gated-handoff-envelope.schema.json -d .github/examples/approval-gated-handoffs/*.json --spec=draft2020`

These are examples only. The starter does not assume Python or Node as a required runtime for validation.

## Approval Rules

1. No overlay-driven handoff should advance without an explicit approval checkpoint.
2. Missing, stale, or rejected approval falls back to the normal guided handoff path.
3. The overlay should reuse the existing `postToolUse` audit seam rather than invent new core hook phases.
4. Keep this overlay additive. Do not rewrite the baseline agent contracts for repos that do not opt in.

## Recommended Adoption Path

1. Enable the overlay only after the repo has stable specialist roles and a repeatable handoff pattern.
2. Start with documentation and structured prompts before attempting any stronger enforcement.
3. Record the enablement decision in an ADR.
4. Review the overlay again if it begins to look like a workflow engine rather than an approval-gated transition layer.

## Consistency Check

Use the lightweight repo-local checks to confirm the overlay assets stay aligned:

- PowerShell: `.github/scripts/check-approval-gated-orchestration.ps1`
- Shell: `.github/scripts/check-approval-gated-orchestration.sh`

If you want one entry point for the broader starter checks, use:

- PowerShell: `.github/scripts/check-starter-workflow.ps1`
- Shell: `.github/scripts/check-starter-workflow.sh`

The checks verify that the manifest, main docs, ADR, schema, and overlay assets are all present and still reference the orchestration overlay consistently.

## Dry Walkthrough

This repo ran a dry walkthrough for the task: `Add a lightweight orchestration overlay module for teams that later want approval-gated auto-handoffs.`

### Simulated chain

1. `analyst`
Confirmed the repo already reserved orchestration for a future optional overlay, but the overlay module itself did not exist yet.

2. `tech-planner`
Defined the lowest-risk design: default-disabled overlay, workflow assets only, richer transition envelope, and additive audit integration.

3. `architecture-reviewer`
Approved the direction with guardrails: keep the richer envelope overlay-only, reuse the existing audit seam, and treat approval data as workflow metadata rather than hard authorization.

4. `senior-software-engineer`
Reduced the implementation slice to manifest, docs, and ADR updates only. No runtime orchestration, no core behavior change.

5. `code-reviewer`
Flagged the missing implementation points clearly: no overlay entry, no ADR, and no explicit overlay-runbook assets yet.

6. `qa`
Marked the workflow as not ready until the overlay assets, ADR, and docs alignment existed.

## Friction Found And Tightened

The dry walkthrough exposed three recurring handoff problems.

### Friction 1: The next agent did not always know what to read

Fix:

- Added `Inputs for next agent` to the core handoff contract and to the core agent prompts.

### Friction 2: The chain did not clearly say whether it was ready to advance

Fix:

- Added `Decision status` with `ready`, `needs-clarification`, or `blocked` to the core handoff contract and prompts.

### Friction 3: Approval metadata risked leaking into core behavior

Fix:

- Kept richer approval and transition metadata inside this overlay only.
- Left the baseline guided handoff contract small and reusable for all repos.

## When Not To Use This Overlay

- When the repo only needs guided handoffs.
- When approval would be ceremonial and not materially improve safety or traceability.
- When the team is really asking for a workflow engine, scheduler, or autonomous multi-agent system.

In those cases, keep the core model or design a separate, explicitly reviewed orchestration system rather than stretching this overlay past its intended scope.
