---
applyTo: "{**/app/game/**/*.{ts,js,mjs}}"
---
# Game Performance Instruction Overlay

These rules are an optional overlay for game code under `app/game/`. They apply to any engine and stay additive to `gameplay-systems.instructions.md`.

## Budget Before Optimization
- State the target frame budget for the lowest supported device before changing code. At 60 FPS the whole frame is about 16.7 ms; treat 16 ms as the working ceiling and reserve headroom for the browser and operating system.
- Record the budget in the repo (runbook, config, or a profiling note) so later changes can be judged against a fixed number.
- Do not optimize speculative code paths. Profile first, fix the measured bottleneck, then re-measure.

## Measure, Then Change
- Capture a baseline before the change and the same measurement after it. Report both numbers together with the device, browser, and scene used.
- Prefer engine instrumentation and browser tooling (performance panel, memory snapshots, frame timelines) over intuition.
- Classify the bottleneck before fixing it: main-thread script time, draw calls, texture upload or fill rate, garbage collection, or asset decode.
- If a measurement cannot be taken, say so and state the assumption instead of claiming an improvement.

## Per-Frame Allocation And Garbage Collection
- Avoid allocating inside the update loop: no new objects, arrays, closures, or per-frame string building.
- Reuse instances and pool frequently created objects such as bullets, particles, enemies, and damage numbers.
- Prefer in-place mutation of preallocated vectors, and reuse result objects instead of returning new ones.
- Watch for hidden allocations: copying array methods, spread operators, `map`/`filter` in hot paths, per-entity closures, and debug text rebuilt every frame.
- Release pools on scene shutdown so memory does not grow across scene transitions.

## Draw Calls, Textures, And Fill Rate
- Batch sprites with texture atlases instead of loading many standalone images.
- Avoid per-frame texture swaps and avoid generating textures at runtime inside the loop.
- Cull off-screen and inactive objects, and disable update and render on pooled objects that are not in use.
- Keep overdraw under control: full-screen overlays, gradients, and large translucent blits are expensive on fill-limited devices.
- Prefer a fixed logical resolution with the scale manager over resizing the render surface every frame.

## Loading And Memory
- Load assets per scene rather than all at boot, and unload what a scene no longer needs.
- Stream or chunk large data such as tilemaps, level data, and audio instead of parsing one large blob at startup.
- Never decode images or audio into memory that the current scene does not use.
- Verify memory across scene transitions and across repeated play sessions, not only at startup.

## Reporting Performance Work
- Report all of: the budget, the baseline, the change, the result, the device, and the repro scene or steps used.
- Keep profiling notes with the change so the result can be re-verified later.
- Treat an unexplained regression as a blocker rather than shipping it behind a lower quality setting.
