---
name: ui-scaffold
description: Optional overlay skill for scaffolding a UI or interaction flow from a product or UX spec with predictable states and test or story stubs.
---
# Skill: ui-scaffold

## When to Use
Use this skill when building a new screen, component flow, or interaction surface and the repo already has an established UI framework and component pattern.

Before scaffolding, read the repo's active UI-related instruction overlays (frontend, React, Next.js, Livewire, Inertia, Alpine, Filament) and follow them over generic patterns. Consult the official documentation for the installed framework versions and cite references for non-obvious patterns.

## Trigger Examples
- "Scaffold the account settings screen from this spec."
- "Generate component structure and states for this feature UI."
- "Create React UI stubs and tests for this workflow."
- "Create Vue or Svelte component stubs for this workflow."
- "Create Livewire component and Blade view stubs for this workflow."
- "Create Inertia page and prop structure for this screen."
- "Scaffold a Filament resource and form schema for this admin screen."
- "Create Alpine.js interaction stubs for this Blade template."

## Checklist
- Parse screen spec: goals, actors, data dependencies, actions, constraints.
- Define component or view structure aligned with repository naming conventions.
- Model predictable UI states: loading, error, empty, success.
- Define props and local/shared state boundaries.
- Generate implementation stubs and basic tests or story stubs based on repo style.
- Honor the repo's active UI-related instruction overlays.
- Consult official documentation for the installed framework versions; cite references for non-obvious patterns.
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
