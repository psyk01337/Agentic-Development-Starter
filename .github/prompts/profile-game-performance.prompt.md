# Profile Game Performance

Use this prompt to diagnose and fix a frame-time, memory, or loading problem in game code.

## Context To Inspect First

- `.github/instructions/game-performance.instructions.md` for budget, measurement, and allocation rules.
- The active engine overlay (for example `.github/instructions/phaser.instructions.md`) for engine-specific profiling and rendering guidance.
- The scene, system, or asset path named in the symptom.
- Existing profiling notes, budget records, or prior performance changes in the repo.
- Official engine documentation for the debugging and rendering statistics APIs of the installed version.

## Deliverables

- The stated frame budget for the target device, or an explicit statement that no budget exists yet.
- A baseline measurement with the device, browser, and scene or repro steps used.
- A bottleneck classification: script time, draw calls, fill rate, garbage collection, asset decode, or loading.
- The cheapest probe that confirms or refutes the leading hypothesis before any fix.
- The smallest fix for the measured bottleneck.
- A post-change measurement using the same method as the baseline.
- Profiling notes committed with the change so the result can be re-verified.

## Safety Boundaries

- Do not optimize without a measurement; state the assumption instead of claiming a win.
- Do not trade away correctness, determinism, or save compatibility for speed.
- Do not add per-frame allocation as a shortcut, and do not disable pooling to simplify a fix.
- Do not lower gameplay quality silently; make any quality trade-off explicit and reversible.
- Do not modify shared benchmark or profiling assets to make a number look better.
- Stop and ask before changing the fixed timestep, the render resolution policy, or a shipping quality setting.

## Expected Output

- Budget, baseline, and post-change measurement with devices and repro
- Bottleneck classification and the evidence for it
- The fix applied, kept minimal
- Before/after numbers and the scene used
- Profiling notes location
- Residual risks and any unexplained variance
- Recommended next agent
