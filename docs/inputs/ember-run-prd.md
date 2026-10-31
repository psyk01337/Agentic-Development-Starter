# Ember Run: Product Requirements (source input)

- Type: PRD
- Version: 2026-10-31 draft 1
- Owner: Product
- Confidentiality: Internal
- Intended repo truth: `docs/prd.md`

This file is an **input**. It lives in `docs/inputs/` and is routed into repo truth by
`route-project-inputs.prompt.md` → `ingest-project-docs`. Do not edit it after routing
unless a new version is being ingested.

## Problem

Players on low-end laptops and phones bounce from browser games that stutter on first
load. The usual causes are unoptimised assets, unbounded frame work, and no fixed
timestep. Ember Run is a small canvas game built to prove the opposite: it must stay at
a stable frame rate on modest hardware and remain playable offline.

## Target user

A casual player on a 2019-era laptop or a mid-range phone, with an unreliable connection.
They open a link, and the game is playable within two seconds.

## Goals

1. A single self-contained playable level that runs in a browser with no install.
2. Stable simulation at a fixed timestep, independent of render frame rate.
3. A score that survives a page reload and cannot be trivially forged by editing storage.
4. A playable first session with no tutorial text longer than one sentence.

## Non-goals

- Multiplayer or any network play.
- Accounts, leaderboards, or any server component.
- Level editor.
- Monetisation.

## Functional requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | The player avatar runs to the right automatically and jumps on input. | Must |
| FR-2 | Obstacles spawn on a seeded schedule so a run is reproducible from its seed. | Must |
| FR-3 | Collision with an obstacle ends the run and shows the final score. | Must |
| FR-4 | Score accrues with distance survived and increases with collected embers. | Must |
| FR-5 | The best score persists locally and is shown on the start screen. | Must |
| FR-6 | A run can be restarted without reloading the page. | Must |
| FR-7 | Difficulty ramps with distance up to a defined ceiling. | Should |
| FR-8 | Sound effects can be muted, and the choice persists. | Should |
| FR-9 | The game is playable with touch, keyboard, and pointer input. | Should |

## Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Simulation runs at a fixed 60 Hz step; rendering may drop frames without changing physics. |
| NFR-2 | Steady-state frame budget is 8 ms on the reference device; no per-frame allocation in the hot loop. |
| NFR-3 | Total first-load payload stays under 500 KB including the engine. |
| NFR-4 | No secrets, tokens, or private endpoints in client code. Everything shipped is public. |
| NFR-5 | Any value read back from storage is treated as untrusted and clamped. |
| NFR-6 | Gameplay must not depend on `requestAnimationFrame` timing for correctness. |

## Acceptance criteria

- A run started from a fixed seed produces an identical obstacle sequence every time.
- Halving the render rate does not change the simulated distance for the same inputs.
- Editing the stored best score to a nonsense value does not crash the game, and cannot
  produce an impossible in-game advantage.
- The first load is interactive within two seconds on a throttled connection.
- Every listed non-goal is still absent from the build.

## Constraints

- Browser only, no server. Static hosting is the deployment target.
- The repo's game overlays apply: code lives under `app/game/`.
- Asset storage policy is not yet decided; see `docs/adr/0002-game-asset-storage-policy.md`.

## Open decisions

1. **Engine**: Phaser 4, Phaser 3, or plain Canvas. Affects which engine overlay is enabled.
   Only one engine overlay may be enabled at a time.
2. **Asset storage**: repository large-file storage versus external system of record for
   authoring masters. Recorded as `Proposed` in ADR 0002.
3. **Score authority**: with no server, "cannot be forged" means "cannot be trivially
   forged". Decide explicitly whether a local proof-of-run is in scope for v1.

## Out of scope for v1

Onboarding tutorial, achievements, daily challenges, cloud saves, analytics.
