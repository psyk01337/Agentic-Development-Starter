---
applyTo: "{**/app/game/**/*.go}"
---
# Go Game Development Instruction Overlay

These rules are an optional overlay for Go game code under `app/game/`. They are engine-agnostic wherever the engine does not dictate the decision, and they stay additive to `gameplay-systems.instructions.md`, `game-performance.instructions.md`, `game-assets-pipeline.instructions.md`, and `.github/instructions/security.instructions.md`.

They apply to any Go game toolkit (for example Ebitengine or raylib-go). Keep engine-specific rules in the engine overlay and keep the rules below in this file.

## Engine And Dependency Discipline
- Choose one rendering and toolkit library per game, and confirm it is actively maintained before adopting it: check the latest release date, recent commit activity, issue response, and license. Historically popular Go game libraries exist that are no longer maintained; popularity is not maintenance.
- Pin exact module versions in `go.mod` and commit `go.sum`, per `.github/instructions/security.instructions.md`. Do not ship a build that depends on a floating or replaced module.
- Run `govulncheck ./...` before adding a dependency and in CI afterwards: https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck
- Verify each dependency's transitive graph and its platform requirements. Some Go game libraries require cgo, a system graphics toolchain, or a specific compiler; record that in the repo before depending on it.
- Record the license of the engine, the assets, and any font or audio library in the repo; see `game-assets-pipeline.instructions.md`.
- Cite the official documentation for the engine and the exact version in the change summary, per `.github/instructions/core.instructions.md`.

## Toolchain And Module Layout
- Pin the language version with the `go` directive and, where the repo requires an exact toolchain, a `toolchain` line. Verify the semantics in the module reference: https://go.dev/ref/mod
- Track the latest stable Go release and read the release notes before upgrading, because game code is sensitive to garbage-collector and runtime changes.
- Keep the game in its own module under `app/game/` unless the repo already defines a different boundary; do not mix the game's `go.mod` with an unrelated service module.
- Suggested layout: `cmd/<game>/` for the entry point, `internal/` for engine adapters, a pure `internal/sim/` (or similar) package for rules, and `assets/` for content.
- Keep the engine import confined to a thin adapter package. Simulation packages must not import the engine, so they stay testable without a window.
- Prefer the standard library over a dependency for math, encoding, and time handling; fewer dependencies mean a smaller attack surface and a simpler build.

## Simulation And Presentation Separation
- Keep rules, state transitions, and scoring in pure packages that do not import the engine, the window, or the audio API.
- Let the presentation layer read simulation state and draw it. Never let rendering mutate simulation state.
- Keep entity and world state in plain structs and slices so it can be serialized, snapshotted, and asserted in tests.
- Route player intent through an input model rather than letting platform event handlers drive state directly.
- Accept state in and return state out, so a system can be exercised in a table-driven test with no engine running.

## Time, Determinism, And The Loop
- Drive gameplay from an explicit fixed timestep with an accumulator. Never scale gameplay logic by the raw frame delta.
- Clamp the accumulator so a stalled or backgrounded window cannot produce an unbounded catch-up loop.
- Keep one authoritative update path per tick. Do not mutate state from input callbacks, goroutines, and draw callbacks simultaneously.
- Seed randomness from an explicit stored seed and use a local source (for example a `math/rand/v2` PCG or ChaCha8 source) rather than a shared global: https://pkg.go.dev/math/rand/v2
- Do not depend on `time.Now()`, wall-clock duration, frame count, or map iteration order for gameplay outcomes. Map iteration order is intentionally randomized in Go.
- Where the engine exposes its own fixed-timestep update, use it instead of building a second loop in parallel.

## Concurrency And Goroutines
- Treat the engine's update and draw path as a single writer. Long-running work such as level generation, AI search, save I/O, or network calls belongs off the loop, with results handed back through a channel.
- Protect shared state with a mutex or by owning it on one goroutine. Never share a mutable struct across goroutines without synchronization.
- Run tests with the race detector: `go test -race ./...`. A race that only appears under load is still a real defect.
- Never call engine or graphics APIs from a goroutine the engine does not expect. Many toolkits require all render calls on the main thread, so confirm the threading contract in the engine documentation.
- Give every goroutine a cancellation path and shut it down on scene or game exit, so a restart does not leak workers.
- Prefer `context.Context` for cancellation and deadlines over ad-hoc stop channels.

## Memory, Allocation, And The Garbage Collector
- Per-frame allocation is the main Go game performance risk. Avoid allocating in the tick path: no new slices, maps, closures, `fmt.Sprintf`, or interface boxing per frame.
- Preallocate and reuse buffers and slices. Use fixed-capacity backing arrays and reset the length instead of reallocating.
- Use `sync.Pool` for frequently created short-lived objects, and comment why the pool exists.
- Avoid reflection, `any` conversions, and map lookups in the hottest path. Prefer concrete types and slices indexed by entity ID.
- Prefer value types and index-based entity storage over pointer-heavy object graphs, so the collector sees fewer pointers.
- Measure allocation rather than guessing: `go test -bench . -benchmem` reports allocations per operation, and escape analysis (`go build -gcflags=-m`) shows what moved to the heap.
- Check collector behavior under load with `GODEBUG=gctrace=1` or the execution tracer before tuning `GOGC`; a tuning change needs a before and after measurement.
- See `game-performance.instructions.md` for the budget-first workflow.

## Rendering, Assets, And Packaging
- Batch draws and prefer atlases over many small images; texture swaps and per-frame uploads dominate frame time on weak GPUs.
- Cull off-screen and inactive entities, and skip draw work for pooled objects that are not in use.
- Keep asset loading out of the tick path. Decode before the scene runs and unload what is no longer needed.
- Use `embed` for assets that ship inside the binary when the target has no filesystem, and prefer external files when assets are large or user-replaceable: https://pkg.go.dev/embed
- Never place secrets, tokens, or private endpoints in embedded assets; anything shipped in the binary is extractable.
- Validate every asset read from disk or the network as untrusted input (size, type, and range) before decoding.

## Platform Targets And Builds
- Declare the supported platforms in the repo and verify that the chosen engine supports each one. A library that works on desktop may not build for WebAssembly or mobile.
- For web targets, build with `GOOS=js GOARCH=wasm`, then check the produced binary for size and startup time and account for the different filesystem and networking model: https://go.dev/wiki/WebAssembly
- Where cgo is required, document how the graphics toolchain is installed and confirm the cross-compilation story before promising a platform.
- Use build tags for platform-specific code instead of runtime checks with stubbed implementations.
- Keep release builds reproducible: build with `-trimpath`, stamp the version through `-ldflags`, and do not commit build output.
- Never commit signing material, store credentials, or provisioning profiles; see `.github/instructions/security.instructions.md`.

## Error Handling, Lifecycle, And Logging
- Return errors explicitly and handle them where a decision can be made. Do not discard one with `_`.
- Do not panic in the game loop. Reserve `panic` for unrecoverable programmer errors at startup, and recover only at a boundary that is genuinely safe.
- Handle asset-load failure, window-close, and device-loss paths explicitly so the game exits or recovers instead of hanging.
- Free engine resources on shutdown and on scene change; leaked GPU handles accumulate across a session.
- Never log per frame. Log lifecycle events and errors with structured fields, and keep secrets, tokens, and player PII out of logs.

## Testing, Benchmarking, And Profiling
- Unit-test pure simulation packages with table-driven tests: given state and inputs, assert the resulting state: https://pkg.go.dev/testing
- Cover edge cases explicitly: zero entities, simultaneous input, boundary collisions, counter overflow, and maximum-capacity states.
- Use seeded randomness in tests so failures reproduce, and use fuzzing for parsers, save-data decoders, and anything that reads untrusted bytes: https://go.dev/doc/fuzz/
- Benchmark hot paths with `go test -bench . -benchmem`, and keep benchmarks in the same package as the code they measure.
- Profile before optimizing: `runtime/pprof` or `net/http/pprof` for CPU and heap, and the execution tracer for scheduling and collector pauses: https://pkg.go.dev/runtime/pprof and https://go.dev/blog/pprof
- Run `go vet ./...` and a pinned static analyzer in CI, and keep the race detector enabled for the pure-logic packages at minimum.
- Keep engine-dependent tests separate from pure-logic tests so the fast suite runs headless.

## Save Data, Persistence, And Client Trust
- Version every save payload with a schema version and a migration path from each prior version. A format you cannot migrate forward is a shipped defect.
- Validate save data on load and treat it as untrusted input. Prefer JSON with a decoder that rejects unknown fields over `gob`, which is not designed for untrusted input: https://pkg.go.dev/encoding/json
- Bound every decode: cap the number of bytes read before parsing, and guard against decompression or expansion bombs when the payload is compressed.
- Never let a local save alone decide progression, currency, or entitlement; confirm against the authoritative source before it affects anything shared or valuable.
- Fall back to a safe default instead of crashing or wiping progress when a save is unreadable, and tell the player what happened.

## Review Checklist
- Engine choice documented with maintenance status, version, license, and platform support.
- Exact module versions pinned; `go.sum` committed; `govulncheck` clean for the new graph.
- Simulation packages do not import the engine.
- Fixed timestep with a clamped accumulator; seeded local randomness; no map-order or wall-clock dependence.
- No per-frame allocation added, and benchmark or allocation numbers reported for hot-path changes.
- Goroutines have cancellation and shutdown paths; tests run with `-race`.
- Save payloads versioned, validated, bounded, and migrated.
- Assets licensed and attributed; no secrets or private endpoints in code, assets, or logs.
- Target platforms built and smoke-tested, including the WebAssembly build where web is claimed.

## Official References
- Go documentation: https://go.dev/doc/
- Go language specification: https://go.dev/ref/spec
- Effective Go: https://go.dev/doc/effective_go
- Go modules reference: https://go.dev/ref/mod
- Managing dependencies: https://go.dev/doc/modules/managing-dependencies
- Go toolchain selection: https://go.dev/doc/toolchain
- Go testing package: https://pkg.go.dev/testing
- Fuzzing: https://go.dev/doc/fuzz/
- Profiling with pprof: https://go.dev/blog/pprof
- runtime/pprof: https://pkg.go.dev/runtime/pprof
- math/rand/v2: https://pkg.go.dev/math/rand/v2
- embed package: https://pkg.go.dev/embed
- encoding/json: https://pkg.go.dev/encoding/json
- govulncheck: https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck
- staticcheck: https://staticcheck.dev/
- Go WebAssembly: https://go.dev/wiki/WebAssembly
- Ebitengine: https://ebitengine.org/
- Ebitengine API: https://pkg.go.dev/github.com/hajimehoshi/ebiten/v2
- raylib-go: https://github.com/gen2brain/raylib-go
