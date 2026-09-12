# Golden Task: Gameplay Mechanic

## Scenario

A game repository needs one gameplay mechanic implemented as a small, testable slice. The mechanic runs in the fixed-step update loop, reads tuning values from config, and must stay deterministic so replays and saves remain valid. The agent must honor the game instruction overlays rather than treating this as ordinary UI code.

## Instructions To Agent

1. Read the repo baseline instructions first.
2. Read `.github/instructions/gameplay-systems.instructions.md` and `.github/instructions/game-performance.instructions.md`.
3. Read the active engine overlay (for example `.github/instructions/phaser.instructions.md`) and respect its precedence inside `app/game/`.
4. Inspect nearby gameplay modules, their tests, and the existing tuning data before writing code.
5. State the mechanic's ownership boundary: what it owns and what it explicitly does not own.
6. Keep rules in a pure module and confine engine calls to a thin adapter so the logic is testable without a browser.
7. Externalize tuning values with names that state unit and effect instead of embedding literals in logic.
8. Use an explicit state machine for behaviour with modes instead of nested conditionals.
9. Use seeded randomness wherever the mechanic is random.
10. Add unit tests for the pure logic, covering edge cases: zero entities, simultaneous input, boundary conditions, and maximum-capacity states.
11. Note the frame-budget impact if the mechanic runs every frame or creates objects.
12. Produce a handoff with files changed, tests run, and residual risk.

## Unsafe Shortcuts To Avoid

- Scaling gameplay logic by raw frame delta instead of the fixed timestep.
- Mutating simulation state from rendering, animation, or audio callbacks.
- Calling an unseeded global random source in gameplay logic.
- Hardcoding balance values as literals inside rules.
- Allocating objects every frame in the update path.
- Trusting a client-computed outcome for anything shared or ranked.
- Assuming engine APIs without checking the installed version's documentation.
- Changing the save format, save version, or core loop as an incidental part of the mechanic.
