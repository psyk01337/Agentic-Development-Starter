---
name: embedded-bringup
description: Bring up and debug embedded firmware on real or emulated hardware with explicit target, memory, timing, recovery, and on-target evidence.
---
# Skill: embedded-bringup

## When to Use
Use this skill when a firmware image, board, peripheral, RTOS task, or low-level driver must be brought up, debugged, or validated on real or emulated hardware.

## Trigger Examples
- "Bring up this new STM32 board and prove the toolchain and flash path work."
- "The firmware hangs after reset; find out why before changing the application."
- "This sensor works on the dev board but fails on the custom PCB."
- "Check the interrupt timing and stack budget before release."

## Checklist
- Record the target MCU or SoC, board revision, toolchain, RTOS or bare-metal choice, clock and power tree, memory map, boot chain, and recovery path.
- Reproduce on the target or an emulator. Capture the reset reason, fault registers, serial logs, and the exact build artifact under test.
- Prove the toolchain and flash path with a minimal blinky or hello-world image before debugging the application.
- Check pin mux, clocks, power rails, strapping, boot mode, watchdog, and debug access.
- Inspect the map file for Flash and RAM use; budget stack and heap; enable assertions and static analysis.
- Test interrupts, concurrency, priorities, critical sections, timing, watchdog recovery, brownout, and error paths.
- Separate pure logic tests that run on the host from on-target or hardware-in-the-loop tests.
- Record evidence as pointers: build artifact and hash, map file, serial log, logic-analyzer or oscilloscope capture, fault dump, and on-target test result.

## Safety Boundaries
- Confirm a recovery path (DFU, JTAG, SWD, or bootloader) before flashing. Do not risk bricking a device.
- Stop and ask before changing fuses, secure boot, bootloader, clock tree, power tree, or partitioning.
- Do not run untrusted firmware on hardware you do not control.
- Stop on hardware damage risk, safety-critical behavior, or regulatory implications.

## Output Format (Strict)
1. Target and setup
- Board, MCU or SoC, toolchain, RTOS, build artifact, and recovery path.

2. Symptom and reproduction
- Expected behavior, observed behavior, and the smallest reliable reproduction.

3. Findings
- Confirmed facts, measurements, and the root cause or leading hypotheses.

4. Fix or next experiment
- The smallest change or the next discriminating experiment.

5. Evidence
- Pointers to the map file, logs, captures, fault dumps, and on-target tests.

6. Residual risk
- Untested boards, timing margins, environmental limits, and open hardware questions.

7. Handoff
- Recommended next agent, inputs, decision status, and blockers or approvals needed.
