---
name: bug-triage
description: Narrow an issue from symptoms to likely causes, missing evidence, and the next safest decision.
---
# Skill: bug-triage

## When to Use
Use this skill when a defect, regression, or production issue is still ambiguous and needs structured triage before design or implementation work begins.

## Trigger Examples
- "Triage this bug before we start fixing it."
- "Narrow the likely cause of this regression."
- "Help me sort symptoms, evidence, and next steps for this issue."

## Checklist
- Restate the reported symptom, impact, and affected area.
- Separate confirmed evidence from assumptions and missing data.
- Identify the most likely causes and the weakest assumptions.
- Note what logs, repro steps, tests, or traces are still missing.
- End with the smallest next decision or action.

## Output Format (Strict)
Produce sections in this exact order:
1. Symptom Summary
- What is happening, where, and why it matters.
2. Confirmed Evidence
- Facts supported by code, logs, repro, or observed behavior.
3. Likely Causes
- Ordered by likelihood, with the weakest assumption called out.
4. Missing Evidence
- What still needs to be gathered.
5. Recommended Next Step
- The smallest safe next action.