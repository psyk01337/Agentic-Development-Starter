---
applyTo: "{**/app/game/**/*.{ts,js,mjs}}"
---
# Gameplay Systems Instruction Overlay

These rules are an optional overlay for game logic under `app/game/`. They are engine-agnostic and stay additive to the engine overlay (for example `phaser.instructions.md`) and to `.github/instructions/security.instructions.md`.

## Simulation And Presentation Separation
- Keep rules, state transitions, and scoring in pure modules that do not touch the renderer, the DOM, or the audio system.
- Let the presentation layer read simulation state and draw it. Never let rendering mutate simulation state.
- Make systems importable and testable without booting the engine: accept state in, return state out.
- Keep entity and world state in plain data structures so it can be serialized, snapshotted, and asserted in tests.
- Route player intent through an input model rather than letting UI code drive state directly.

## Time, Determinism, And The Loop
- Drive gameplay from an explicit fixed timestep with an accumulator. Never scale gameplay logic by the raw frame delta.
- Keep a single authoritative update path per frame. Do not scatter state mutation across input callbacks, tweens, and render callbacks.
- Seed randomness from an explicit, stored seed. Never call an unseeded global random source in gameplay logic.
- Do not depend on wall-clock time, frame count, or object iteration order for gameplay outcomes.
- Clamp the accumulator so a stalled tab or a long frame cannot produce an unbounded catch-up loop.

## State Machines Over Conditionals
- Model entity behaviour as an explicit state machine with named states and allowed transitions.
- Make transition rules declarative and data-driven instead of nesting conditionals across update functions.
- Reject invalid transitions explicitly and log them in development builds.
- Keep animation and audio triggers in the presentation layer, keyed off state transitions rather than embedded in rules.

## Data-Driven Tuning
- Keep balance values (speeds, costs, damage, cooldowns, spawn tables) in data files or config modules, never as literals inside logic.
- Give every tuning value a name that states its unit and its effect.
- Keep tuning data versioned with the code that reads it so a save or replay can still be interpreted later.
- Treat a balance change as a reviewable change with a stated intent and a recorded before/after observation.

## Save Data And Progression
- Version every save payload with a schema version and a migration path from each prior version.
- Validate save data on load and treat it as untrusted input; fall back to a safe default rather than crashing.
- Keep progression and currency arithmetic on the authoritative side, as described in `phaser.instructions.md` and the security baseline.
- Never ship a save format that cannot be migrated forward.

## Testing Game Logic
- Unit-test pure simulation modules directly: given a state and inputs, assert the resulting state.
- Cover edge cases explicitly: zero entities, simultaneous input, boundary collisions, counter overflow, and maximum-capacity states.
- Use seeded randomness in tests so failures are reproducible.
- Keep engine-dependent tests separate from pure-logic tests so the fast suite runs without a browser.

## Boundaries
- Do not put render-only concerns (sprite keys, texture names, camera effects) in simulation modules.
- Do not let persistence concerns leak into rule evaluation; pass the data in through a parameter.
- Stop and ask before changing the save format, the fixed timestep, or the core loop, because those changes invalidate existing saves and replays.
