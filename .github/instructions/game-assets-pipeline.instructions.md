---
applyTo: "{**/app/game/assets/**}"
---
# Game Assets Pipeline Instruction Overlay

These rules are an optional overlay for game asset directories. They cover storage boundaries, provenance and licensing, naming, derived-asset discipline, and safe handling of binary content.

## Storage Boundary
- Treat assets as two distinct classes and keep them in separate directories:
  - Authoring masters: editable source files that a person opens and edits.
  - Runtime assets: optimized files that the game loads and ships.
- Only runtime assets are loaded by game code. Never load a master from a gameplay path.
- Runtime assets must be reproducible from masters by a documented, scripted step. A runtime asset that cannot be regenerated is a defect.
- The repository storage policy for masters is repo-specific. Use `.github/examples/game-dev/gitattributes.addendum` as the starting point and record the decision in an ADR. Do not assume large-file storage is configured.

## Provenance And Licensing
- Record the origin of every third-party asset: source URL, author, license, and any required attribution.
- Never commit an asset whose license is unknown or that does not permit redistribution. Treat that as a blocker, not a warning.
- Keep a machine-readable asset manifest (id, file, source, license, attribution text) beside the assets it describes.
- Include required attribution in the shipped build where the license demands it.
- Do not commit assets borrowed from a copyrighted game, film, stock library, or asset store without a recorded purchase or license.

## Naming And Organization
- Use lowercase, hyphenated, path-stable names. Never rename a shipped asset path without updating its references in the same change.
- Group assets by purpose (sprites, atlases, audio, tilesets, data) rather than by file extension.
- Keep one canonical location per asset. Do not duplicate the same file into two directories.
- Never put credentials, tokens, API keys, or personal data into asset files, metadata, or filenames.

## Derived Assets And Determinism
- Generate atlases, compressed textures, and compressed audio with a scripted step, not by hand in a GUI.
- Pin the tool versions that produce derived assets, and check the tool config or lockfile into the repo.
- Make the step deterministic: the same masters and the same tool version must produce the same output.
- Never hand-edit a derived asset. Fix the source or the pipeline instead.
- Keep generated output out of review noise by regenerating rather than patching.

## Formats And Sizing
- Choose formats for the target browsers and the installed engine version, and verify support against official documentation before adopting a format.
- Use texture atlases for sprites that are drawn together, to reduce draw calls.
- Size images for the largest on-screen use, and account for device pixel ratio instead of shipping oversized art.
- Use compressed audio with a documented fallback format, and keep music and effects in separate files so effects can load first.
- Verify that every runtime asset referenced by code or data exists and is reachable from the loader.

## Verification
- Verify the pipeline from a clean checkout: run the documented steps and confirm the game loads with no missing-asset errors.
- Confirm the asset manifest covers every third-party asset.
- Confirm no master file is referenced from a runtime load path.
- Stop and ask before deleting or force-replacing assets, rewriting asset history, or changing the storage policy for masters.
