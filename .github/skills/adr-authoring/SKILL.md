---
name: adr-authoring
description: Draft concise architecture decision records from a design choice, tradeoff, or workflow decision using the repo's ADR template.
---
# Skill: adr-authoring

## When to Use
Use this skill when a design, workflow, security, or architecture decision should be recorded as an ADR.

## Trigger Examples
- "Write an ADR for this workflow decision."
- "Turn this architecture choice into an ADR."
- "Draft the decision record for this rollout policy."

## Checklist
- Confirm the decision is durable enough to justify an ADR.
- Identify the decision, context, constraints, and alternatives.
- Capture the selected option and its consequences clearly.
- Use the nearest ADR template and repository naming convention.
- Keep the ADR short, explicit, and decision-focused.

## Output Format (Strict)
Produce sections in this exact order:
1. ADR Title
- Proposed title for the decision record.
2. Context
- Key constraints, forces, and why the decision is needed.
3. Decision
- The chosen option in one concise paragraph.
4. Consequences
- Positive outcomes, tradeoffs, and operational impact.
5. Open Questions
- `None` if the ADR is ready, otherwise the unresolved points.