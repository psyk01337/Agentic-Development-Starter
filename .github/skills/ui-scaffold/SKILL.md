---
name: ui-scaffold
description: Scaffold UI structure from a screen specification with predictable states and test/story stubs.
---
# Skill: ui-scaffold

## When to Use
Use this skill when building a new screen/component flow from product or UX specs.

## Trigger Examples
- "Scaffold the account settings screen from this spec."
- "Generate component structure and states for this feature UI."
- "Create React UI stubs and tests for this workflow."

## Checklist
- Parse screen spec: goals, actors, data dependencies, actions, constraints.
- Define component tree aligned with repository naming conventions.
- Model predictable UI states: loading, error, empty, success.
- Define props and local/shared state boundaries.
- Generate implementation stubs and basic tests or story stubs based on repo style.
- Include accessibility checks for keyboard flow and semantics.

## Output Format (Strict)
Produce sections in this exact order:
1. Component Tree
- Parent/child structure list.
2. Props
- Component props contracts.
3. State Model
- Source of truth, derived state, and transitions.
4. Implementation Steps
- Ordered, minimal-risk steps to build.
