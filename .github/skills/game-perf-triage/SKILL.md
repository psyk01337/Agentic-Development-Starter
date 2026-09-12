---
name: game-perf-triage
description: Turn a game performance symptom into a measured budget, a classified bottleneck, and one verified fix.
---
# Skill: game-perf-triage

## When to Use
Use this skill when a game feels slow, stutters, drops frames, hitches on load, or grows in memory, and the cause is not yet known. Use it before optimizing any game code path.

## Trigger Examples
- "Use game-perf-triage on this frame drop in the combat scene."
- "The game stutters when many enemies spawn; find the bottleneck before I optimize."
- "Triage the memory growth across scene transitions."
- "We load everything at boot and first load is slow; triage it."

## Checklist
- State the target frame budget, or record explicitly that no budget exists yet.
- Capture a baseline with device, browser, and repro scene or steps.
- Classify the bottleneck: script time, draw calls, fill rate, garbage collection, asset decode, or loading.
- Name the cheapest probe that confirms or refutes the leading hypothesis.
- Apply the smallest fix for the measured bottleneck only.
- Re-measure with the same method and the same scene as the baseline.
- Record before/after numbers and where the profiling notes live.
- List what was not measured and which devices or scenes remain unverified.

## Guardrails
- Never claim a performance improvement without a before and after measurement.
- Never trade determinism, save compatibility, or correctness for frame time.
- Never add per-frame allocation, disable pooling, or lower a shipping quality setting as a shortcut.
- If a measurement cannot be taken, say so and label the conclusion an assumption.
- Stop and ask before changing the fixed timestep, the render resolution policy, or a shipping quality setting.

## Output Format (Strict)
Produce sections in this exact order:

1. Symptom And Budget
- The reported symptom, the affected scene or flow, and the target budget.
2. Baseline
- Measured numbers, device, browser, and repro steps.
3. Bottleneck Classification
- The category, the supporting evidence, and the confidence level.
4. Cheapest Probe
- The single measurement or experiment that confirms or refutes the leading hypothesis.
5. Fix Applied
- The smallest change made, and why it targets the measured bottleneck.
6. After Measurement
- The same numbers re-taken with the same method and scene.
7. Prevention Rules
- The budget, pooling, or scaling rule that stops the problem recurring.
8. Residual Risk
- What was not measured, and which devices or scenes remain unverified.
