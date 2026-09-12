# Prepare Game Build

Use this prompt to prepare and verify a shippable browser game build.

## Context To Inspect First

- `.github/instructions/game-assets-pipeline.instructions.md` for asset provenance, licensing, and derived-asset rules.
- `.github/instructions/security.instructions.md` for secret handling and the client-trust boundary.
- The active engine overlay (for example `.github/instructions/phaser.instructions.md`) for asset loading rules.
- The build configuration, lockfiles, and deployment target config.
- `.github/examples/game-dev/gitignore.addendum` and `.github/examples/game-dev/gitattributes.addendum` for the asset storage policy in use.
- Official documentation for the build tool and hosting target before changing either.

## Deliverables

- A clean-checkout build that succeeds from the documented steps alone.
- Confirmation that no secrets, tokens, private endpoints, or credentials are present in the shipped bundle or assets.
- Confirmation that every shipped asset is covered by a recorded license or is original work, with attribution included where required.
- A version or build stamp that identifies the exact build.
- Confirmation that derived runtime assets regenerate from masters deterministically.
- A smoke test result covering first load, a scene transition, and a save/restore cycle.
- A changelog entry for any executable or build-behavior change.

## Safety Boundaries

- Never write credentials, tokens, or private endpoints into build config, assets, or committed files.
- Do not commit build output that is reproducible, and do not commit signing material or store credentials.
- Do not delete, rewrite, or force-replace asset history as part of a build fix.
- Do not ship an asset with an unknown or non-redistributable license.
- Do not disable validation, type checks, or tests to make a build pass.
- Stop and ask before changing the asset storage policy, deleting assets, or altering deployment credentials.

## Expected Output

- Build command and result from a clean checkout
- Secret and credentials scan result
- Asset license and attribution confirmation
- Version stamp value
- Smoke test result with the environment used
- Changelog entry
- Known gaps and residual risks
- Recommended next agent
