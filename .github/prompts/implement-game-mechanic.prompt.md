# Implement Game Mechanic

Use this prompt to implement one gameplay mechanic as a small, testable slice.

## Context To Inspect First

- `.github/instructions/gameplay-systems.instructions.md` for simulation, determinism, and tuning rules.
- `.github/instructions/game-performance.instructions.md` when the mechanic runs every frame or creates objects.
- The active engine overlay (for example `.github/instructions/phaser.instructions.md`) for engine-specific rules and precedence.
- The design or issue this mechanic comes from, plus nearby systems and their tests.
- Existing tuning data files and the save schema if the mechanic reads or writes either.
- Official engine documentation for the installed version before using any engine API.

## Deliverables

- The smallest implementation that delivers the mechanic, with rules in pure modules and engine calls confined to a thin adapter.
- Tuning values externalized to data or config with names that state unit and effect.
- Explicit state transitions instead of nested conditionals.
- Seeded randomness wherever the mechanic is random.
- Unit tests for the pure logic, including edge cases: zero entities, simultaneous input, boundary conditions, and maximum-capacity states.
- A changelog entry when the change affects executable behavior.
- Notes on frame-budget impact if the mechanic runs per frame.

## Safety Boundaries

- Keep the change scoped to the requested mechanic; do not refactor adjacent systems.
- Do not change the fixed timestep, the save format, or the save version as part of a mechanic.
- Do not allocate per frame in hot paths; use pools or reuse existing objects.
- Do not read balance values from literals inside logic.
- Do not trust client-computed outcomes for anything shared, ranked, or valuable.
- Stop and ask before any change that would invalidate existing saves, replays, or tuning data.

## Expected Output

- Mechanic implemented as a reviewable slice
- Tuning values added and named
- Tests added or updated, with the command run and result
- Frame-budget note when relevant
- Changelog entry
- Residual risks and untested paths
- Recommended next agent
