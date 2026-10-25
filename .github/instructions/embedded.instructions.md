---
applyTo: "{**/firmware/**,**/embedded/**,**/boards/**,**/*.ino,**/platformio.ini,**/*.ld,**/memory.x,**/sdkconfig.defaults}"
---
# Embedded Systems Overlay Instructions

These rules are an optional overlay for embedded firmware, board support, and hardware bring-up work. They are additive to `.github/instructions/core.instructions.md` and `.github/instructions/security.instructions.md`.

## Target And Recovery First
- Record the MCU or SoC, board revision, toolchain version, RTOS or bare-metal choice, clock and power tree, memory map, and boot chain before changing firmware.
- Confirm a recovery path (DFU, JTAG, SWD, or bootloader) before flashing. Do not risk bricking a device.
- Keep the build artifact, hash, and flash command with the result so a finding can be reproduced.

## Resource Budgets
- Treat Flash, RAM, stack, heap, and power as explicit budgets. Inspect the map file after every meaningful change.
- Prefer static allocation or bounded pools in safety-critical paths. Check stack high-water marks and heap fragmentation.
- Enable compiler warnings, assertions, and static analysis appropriate to the toolchain.

## Timing And Concurrency
- Model interrupt priorities, critical sections, and shared-state access explicitly. Use `volatile` or atomics only where the memory model requires them.
- Do not block in interrupt context. Keep ISRs short and defer work to a task or main loop.
- Use a watchdog with a tested recovery path; do not feed it unconditionally.
- Measure timing on the target or an emulator; do not infer real-time behavior from host tests.

## Hardware Boundaries
- Verify pin mux, clock sources, power rails, strapping, boot mode, and reset behavior before application logic.
- Check the errata and electrical limits for the exact part and board revision.
- Keep hardware abstraction boundaries explicit so board-specific code does not leak into portable logic.

## Testing
- Unit-test pure logic on the host. Keep hardware-in-the-loop tests separate and reproducible.
- Cover boot failure, watchdog reset, brownout, sensor or bus timeout, full queues, and recovery paths.
- Test the actual target or a faithful emulator; record the setup.

## Safety
- Stop and ask before changing fuses, secure boot, the bootloader, the clock tree, the power tree, or partitioning.
- Do not run untrusted firmware on hardware you do not control.
- Stop on hardware damage risk, safety-critical behavior, or regulatory implications.

## Evidence
- Point to the build artifact and hash, map file, serial log, logic-analyzer or oscilloscope capture, fault dump, and on-target test result instead of pasting long output.
