---
applyTo: "{**/app/game/**/*.{ts,js,mjs,json,html,css}}"
---
# Phaser 4 Instruction Overlay (JavaScript And TypeScript)

These rules are an optional overlay for repositories that build browser games with Phaser 4. They extend `phaser.instructions.md` (engine group rules that apply to Phaser generally) with Phaser 4-specific practice, and they stay additive to `gameplay-systems.instructions.md`, `game-performance.instructions.md`, `game-assets-pipeline.instructions.md`, and `.github/instructions/security.instructions.md`.

Where a general Phaser rule and a Phaser 4 rule disagree, this file wins inside `app/game/` because it is the more specific overlay.

## Verify The Version Before You Write Code
- Confirm the current Phaser 4 release line, dist-tags, and release notes from the official sources before writing engine code: https://phaser.io/, https://phaser.io/news, and https://github.com/phaserjs/phaser.
- Check what npm actually resolves before pinning: `npm view phaser dist-tags` and `npm view phaser versions --json`. Prerelease and stable channels use different dist-tags, and pinning a prerelease by accident is both a stability and a supply-chain risk.
- Pin the exact version (no `^` or `~`) in `package.json` and commit the lockfile, per `.github/instructions/security.instructions.md`.
- Confirm whether the installed package ships its own TypeScript declarations or needs a separate types package, and use the declarations that match the installed version. Do not maintain a parallel hand-written `phaser.d.ts` shim.
- Treat the Phaser 3 documentation, examples, and community tutorials as a different API surface. Verify every method, config key, and constant against the Phaser 4 documentation or the installed declarations before using it.
- Cite the documentation link for every non-obvious engine API in the change summary, per `.github/instructions/core.instructions.md`.

## Do Not Mix Phaser 3 And Phaser 4 Idioms
- Do not paste Phaser 3 snippets into a Phaser 4 codebase and patch the errors by guesswork. If a v3 pattern looks wrong, find the v4 equivalent in the documentation or the release notes.
- Read the upgrade and changelog notes for every minor version you cross, and resolve each behavior change deliberately rather than silently.
- Treat an engine upgrade as its own reviewable change with a stated intent, a tested surface list, and a recorded before/after observation. Do not fold a major-version bump into an unrelated feature diff.
- Re-verify every third-party Phaser plugin against Phaser 4 before keeping it. A plugin written for Phaser 3 is not assumed compatible, and an unmaintained plugin that patches engine internals is a removal candidate.
- Keep exactly one Phaser version in the dependency graph. Two copies of the engine in a bundle produce duplicate state and hard-to-diagnose renderer bugs.

## TypeScript And Project Structure
- Prefer TypeScript for game code and keep `strict` enabled; types are how the v4 API surface is verified at build time.
- Avoid `any` at engine boundaries. If a declaration is genuinely loose, isolate it in one typed adapter instead of leaking `any` through gameplay code.
- Type scene data explicitly (scene keys, init data, registry keys) rather than relying on untyped string lookups.
- One scene per file, named after the scene it owns (`BootScene`, `PreloadScene`, `MainMenuScene`, `LevelScene`).
- Keep the game config in one exported module: renderer choice, physics, scale mode, input, and plugin registration. Do not scatter config across the entry point and individual scenes.
- Keep gameplay systems in their own modules and let scenes orchestrate them; see `gameplay-systems.instructions.md`.

## Scene Lifecycle Discipline
- Put setup in `create`, per-frame work in `update`, and teardown in a shutdown or destroy handler. Do not add objects, wire listeners, or start tweens from `update`.
- Register listeners in `create` and remove the same references in the matching shutdown handler, so a scene restart cannot stack duplicate handlers.
- Clean up timers, tweens, and pooled objects on shutdown, and release pooled instances rather than letting them leak across transitions.
- Guard scene transitions with an explicit state flag; do not assume the scene manager ignores a duplicate start on the same frame.
- Re-verify lifecycle and shutdown event names against the Phaser 4 documentation instead of carrying v3 names forward from memory.

## Renderer, Scaling, And Camera
- Choose the renderer explicitly in the game config, and confirm which renderers the installed version provides and which the supported browsers expose. Do not assume a WebGL-only or WebGPU-only path is safe for every device you claim to support.
- Set an explicit scale mode and logical resolution. Prefer `FIT` with `CENTER_BOTH` for fixed-aspect games over resizing the surface every frame; see `game-performance.instructions.md`.
- Size the canvas container in CSS and let the scale manager own the render surface. Do not fight the scale manager with per-frame canvas sizing.
- Use camera effects (shake, flash, fade) through the camera API rather than transforming the DOM or manually offsetting objects.
- Handle context loss and restore explicitly where the renderer exposes it; a lost context must not leave the game in a silent dead state.
- Verify renderer- and scale-related config keys against the installed version's documentation before relying on them.

## Assets And Loading
- Load in a preload scene, not inside gameplay scenes, and unload what a scene no longer needs.
- Prefer texture atlases over many standalone images, and keep a naming convention that maps atlas frames to logical asset names.
- Handle loader failures explicitly: log the failing key and fail the boot path visibly instead of continuing with missing frames.
- Never place secrets, tokens, private endpoints, or licensed material without recorded attribution in assets; see `game-assets-pipeline.instructions.md`.
- Do not parse asset files straight into gameplay config. Validate shape, type, and range first.

## Input
- Read input state in `update` from the input manager instead of acting inside raw DOM handlers.
- Centralize key and pointer bindings in one module so they can be remapped, and support keyboard and pointer for any action that matters.
- Feature-detect gamepads rather than assuming one is present, and handle disconnect mid-session.
- Validate pointer data before use: a multi-touch sequence can produce missing or out-of-bounds values.

## State, Persistence, And Client Trust
- Treat `localStorage` and `sessionStorage` as untrusted, user-editable input. Validate and clamp every value read back.
- Never let client storage alone decide progression, currency, unlocks, or entitlement; confirm against the authoritative source before it affects anything shared or valuable.
- Version every persisted payload and provide a migration path, as described in `gameplay-systems.instructions.md`.
- Handle quota and parse failures explicitly; a corrupted save must not produce a black screen.
- Never put secrets, API keys, service tokens, or private endpoints in client code or assets. Anything shipped to the browser is public.

## Performance Practices
- Profile before optimizing and state the frame budget for the lowest supported device; see `game-performance.instructions.md` and the `game-perf-triage` skill.
- Pool repeated objects (bullets, enemies, particles) instead of instantiating them per event.
- Avoid per-frame allocation: no new objects, arrays, closures, spread copies, or per-frame string building inside `update`.
- Cull off-screen and inactive objects, and disable update and render on idle pooled instances.
- Verify memory across scene transitions and repeated play sessions, not only at startup.

## Testing And Verification
- Keep pure simulation logic in modules that can be tested without a browser; see `gameplay-systems.instructions.md`.
- Verify input, scaling, and load paths in a real browser, and record the viewport sizes and devices checked.
- Check the console after every scene transition; a silent asset 404 or a swallowed loader error is a defect, not noise.
- Test the first-load path, a reload mid-session, and a save and restore cycle.
- Smoke-test the built bundle, not only the dev server: confirm the engine is bundled once, assets resolve from deployed paths, and the first frame renders on a cold cache.

## Common Phaser 4 Failure Modes
- Duplicate event listeners after a scene restart, caused by registering handlers without removing them on shutdown.
- Work added to `update` that only needs to run once, such as object creation, listener wiring, or starting a tween.
- A v3 tutorial snippet carried forward that compiles but no longer matches v4 behavior.
- A Phaser 3 plugin that patches engine internals and breaks against the v4 renderer.
- A save payload read from `localStorage` and trusted without validation.
- Assets loaded per scene and never unloaded, so memory grows across a long session.
- A config key taken from memory that the installed version renamed.

## Review Checklist
- Exact Phaser version pinned; lockfile committed; only one engine copy in the dependency graph.
- Engine APIs used in the diff verified against Phaser 4 documentation or shipped declarations.
- Listeners, timers, tweens, and pools torn down on scene shutdown.
- Nothing but per-frame work in `update`; no per-frame allocation added.
- Client storage treated as untrusted; server authority preserved for value-bearing state.
- No secrets, tokens, or private endpoints in client code or assets.
- Browser verification recorded with viewport sizes and the console result.

## Official References
- Phaser: https://phaser.io/
- Phaser API documentation: https://docs.phaser.io/
- Phaser release announcements and news: https://phaser.io/news
- Phaser source, releases, and changelog: https://github.com/phaserjs/phaser
- Phaser examples: https://phaser.io/examples
- Phaser download and version listing: https://phaser.io/download
- npm package metadata (dist-tags and versions): https://www.npmjs.com/package/phaser
