# Design Game System

Use this prompt to design a game subsystem (combat, progression, economy, inventory, spawn director) before implementing it.

## Context To Inspect First

- `.github/instructions/gameplay-systems.instructions.md` for simulation and determinism rules.
- The active engine overlay (for example `.github/instructions/phaser.instructions.md`) for engine-specific constraints.
- Existing pure-logic modules under `app/game/` and their tests, so the design matches current patterns.
- Any existing tuning data, save schema, or progression config that the new system must interoperate with.
- `docs/runbooks/game-dev.md` for the repo's game-specific conventions.
- Official engine documentation for the installed version before proposing engine-dependent APIs.

## Deliverables

- A one-paragraph system statement: what it owns, what it explicitly does not own.
- The data model: entities, state fields, units, and which values are tuning data versus runtime state.
- The update contract: what runs per fixed step, in what order, and what reads versus writes state.
- The state machine or transition table for any entity with modes.
- The tuning surface: named values, units, sensible ranges, and where they live.
- Save and replay impact: whether the schema changes, and the migration path if it does.
- The pure-logic test list: scenarios, edge cases, and seeded-random cases.
- Explicit non-goals and the smallest first slice that proves the design.

## Safety Boundaries

- Keep the design engine-agnostic where possible; isolate engine-dependent parts behind one adapter boundary.
- Do not propose changes to the fixed timestep, the save schema, or the core loop as an incidental part of a new system.
- Do not put rendering, audio, or DOM concerns inside the simulation design.
- Do not invent engine APIs. Verify every engine call against official documentation for the installed version and cite it.
- Stop and ask before changing the save format, the core loop, or an existing public system contract.

## Expected Output

- System statement and ownership boundary
- Data model and tuning surface
- Update order and state transitions
- Save/replay impact and migration path
- Test list for pure logic
- Non-goals and proposed first slice
- Open questions and assumptions
- Recommended next agent
