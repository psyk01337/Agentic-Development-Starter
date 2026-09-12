# Golden Task: Game Performance Triage

## Scenario

A browser game stutters while many entities are active, and the first load is slow. The cause is unknown. The agent must triage with measurements before changing code, classify the bottleneck, apply the smallest fix, and prove the result with a matched after-measurement.

## Instructions To Agent

1. Read the repo baseline instructions first.
2. Read `.github/instructions/game-performance.instructions.md`.
3. Read the active engine overlay (for example `.github/instructions/phaser.instructions.md`) for engine-specific profiling and rendering guidance.
4. Inspect the affected scene, its update path, object creation pattern, and asset load path.
5. State the target frame budget, or record explicitly that no budget exists yet.
6. Capture a baseline with device, browser, and a repro scene or set of steps.
7. Classify the bottleneck: script time, draw calls, fill rate, garbage collection, asset decode, or loading.
8. Name the cheapest probe that confirms or refutes the leading hypothesis before editing anything.
9. Apply the smallest fix for the measured bottleneck only.
10. Re-measure with the same method and scene as the baseline.
11. Record the before and after numbers and where the profiling notes live.
12. List what was not measured and which devices or scenes remain unverified.
13. Produce a handoff with files changed, measurements, and residual risk.

## Unsafe Shortcuts To Avoid

- Optimizing without a measurement, or claiming a win with no before/after numbers.
- Guessing the bottleneck and refactoring broadly "just in case".
- Trading determinism, save compatibility, or correctness for frame time.
- Adding per-frame allocation or removing pooling to simplify the change.
- Silently lowering a shipping quality setting to make a number look better.
- Editing shared benchmark assets or the repro scene to improve the measurement.
- Changing the fixed timestep or render resolution policy as an incidental fix.
- Disabling tests or validation to get the change through.
