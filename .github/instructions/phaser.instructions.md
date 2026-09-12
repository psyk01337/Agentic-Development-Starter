---
applyTo: "{**/app/game/**/*.{ts,js,mjs,json,html,css}}"
---
# Phaser Instruction Overlay (Browser Games)

These rules are an optional overlay for repositories that build browser games with Phaser. They are additive to `.github/instructions/security.instructions.md` and to the frontend overlay, and they take precedence inside `app/game/`.

## Version And Documentation Discipline
- Confirm the current stable Phaser release from the official site and release notes before writing code: https://phaser.io/ and https://docs.phaser.io/
- Pin the exact Phaser version in `package.json` and the lockfile. Do not use floating ranges for the engine.
- Match the installed major version's API surface. Do not mix Phaser 2 patterns into a Phaser 3 codebase or the reverse.
- Consult the official API documentation for every scene lifecycle method, plugin, loader method, and config option you use, and cite the doc link in the change summary.

## Scope And Precedence
- These rules apply only inside game paths, currently `app/game/`.
- Inside `app/game/`, this overlay takes precedence over a React or Next.js overlay. Phaser owns a canvas or WebGL context and a real-time loop, so SSR, hydration, and virtual-DOM lifecycle rules do not apply to game code.
- Keep non-game UI (account pages, storefront, marketing) outside `app/game/` and under the frontend overlay. Cross the boundary through one narrow, documented interface instead of reaching into the game loop from framework code.

## Project Structure
- One scene per file, named after the scene it owns (`BootScene`, `PreloadScene`, `MainMenuScene`, `LevelScene`).
- Separate scenes for boot, preload, menu, and gameplay. Keep asset loading in the preload scene rather than scattered across gameplay scenes.
- Keep gameplay systems in their own modules and let scenes orchestrate them; see `gameplay-systems.instructions.md`.
- Keep configuration (physics settings, scale mode, input bindings) in one exported config module rather than inline in `main`.

## Scene Lifecycle Discipline
- Put setup in `create` and per-frame work in `update`. Do not add/remove objects or wire event listeners in `update`.
- Register event listeners in `create` and remove them in a matching shutdown or destroy handler so scene restarts do not stack duplicate handlers.
- Clean up timers, tweens, and pooled objects when a scene shuts down.
- Avoid starting a scene twice; use the scene manager's start/stop API explicitly and guard transitions with a state flag.

## Game Objects And Systems
- Prefer groups and pools for repeated objects (bullets, enemies, particles) over repeated instantiation. See `game-performance.instructions.md`.
- Use arcade physics for simple AABB-style movement and collision, and the matter physics option only when its extra cost is justified.
- Keep collision callbacks small and side-effect-scoped; route results into the simulation rather than mutating rendering state directly.
- Drive animation from gameplay state instead of letting animation completion determine gameplay outcomes.

## Input
- Read input state in `update` from the input manager rather than acting inside raw DOM event handlers.
- Centralize key and pointer bindings in one module so they can be remapped, and support keyboard and pointer for any action that matters.
- Treat gamepad support as optional and feature-detect it rather than assuming it exists.
- Never read a device or pointer value without validating it; guard against missing pointers on multi-touch and out-of-bounds coordinates.

## Rendering And Scaling
- Set an explicit scale mode and a logical resolution in the game config. Prefer `FIT` with `CENTER_BOTH` for fixed-aspect games over resizing the canvas per frame.
- Keep the game canvas and the surrounding page layout separate: size the canvas container in CSS and let the scale manager handle the render surface.
- Use camera effects (shake, flash, fade) through the camera API instead of transforming the DOM or moving every object manually.
- Verify the accepted resolution set and the current API names against the installed version's documentation before relying on them.

## State, Save Data, And Persistence
- Treat `localStorage` and `sessionStorage` as untrusted, user-editable storage. Validate and clamp every value read back.
- Never store progression, currency, or entitlement decisions in client storage alone; re-derive or confirm them with the authoritative source.
- Version every persisted payload and provide a migration path, as described in `gameplay-systems.instructions.md`.
- Handle quota and parse failures explicitly; a corrupted save must not produce a black screen.

## Security
- Assume every browser-side value is attacker-controlled. A score, unlock, timer, or drop rate computed only on the client is not trustworthy; validate on the server before it affects anything shared or valuable.
- Do not place secrets, API keys, service tokens, or private endpoints in client code or in assets. Anything shipped to the browser is public.
- Never pass untrusted data straight into a loader, `JSON.parse` into gameplay config, or an eval-like path. Validate shape, type, and range first.
- Sanitize player-supplied text (names, chat, scores) before rendering it into the DOM layer; canvas text is safer than injecting HTML.
- Avoid third-party plugins that execute remote code or load scripts from unverified origins, and pin any plugin you do accept.

## Testing And Verification
- Keep pure simulation logic in modules that can be unit-tested without a browser; see `gameplay-systems.instructions.md`.
- Verify real behaviour in a browser for input, scaling, and load paths, and record the viewport sizes and devices checked.
- Check the browser console for errors and warnings after a scene transition; a silent asset 404 is a defect.
- Test the first-load path, a reload mid-session, and a save/restore cycle.

## Official References
- Phaser: https://phaser.io/
- Phaser API documentation: https://docs.phaser.io/
- Phaser examples: https://phaser.io/examples
