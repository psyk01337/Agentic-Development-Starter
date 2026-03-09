---
name: approval-gated-handoffs
description: Optional overlay skill for coordinating approval-gated specialist handoffs while preserving guided handoffs as the core default.
---
# Skill: approval-gated-handoffs

## When to Use
Use this skill when a repo has explicitly opted into the orchestration overlay and the current task needs a structured, approval-gated transition between specialist agents.

## Trigger Examples
- "Coordinate the next specialist handoff, but require explicit approval before advancing."
- "Use the orchestration overlay to prepare the next agent handoff."
- "Draft an approval-gated transition from tech-planner to senior-software-engineer."

## Checklist
- Confirm the repo intends to use the optional orchestration overlay.
- Identify the current agent, proposed next agent, and why the transition is needed.
- Capture the minimum handoff envelope: current agent, next agent, scope summary, reason, approval required, approval status, approver identity if known, approval timestamp if known, transition status, and audit reference if known.
- Keep the envelope aligned to `.github/schema/approval-gated-handoff-envelope.schema.json`.
- Fall back to the normal guided handoff contract if approval is missing, rejected, or stale.
- Keep approval metadata clearly documented as workflow metadata, not enforced authorization.

## Output Format (Strict)
Produce sections in this exact order:
1. Current State
- Current agent, transition status, and scope summary.
2. Proposed Handoff
- Next agent and why the handoff is appropriate.
3. Approval Gate
- Required approval, current approval state, and fallback behavior.
4. Handoff Prompt Draft
- Minimal prompt for the next agent if the transition is approved.
5. Risks
- What could go wrong if the transition proceeds too early or without approval.