# Ember Run: Product Requirements

Repo truth for this repository. Routed from `docs/inputs/ember-run-prd.md` on 2026-10-31.
Edit this file, not the input, when requirements change; re-ingest a new input version
instead of amending history.

| Field | Value |
| --- | --- |
| Source | `docs/inputs/ember-run-prd.md` |
| Source version | 2026-10-31 draft 1 |
| Owner | Product |
| Confidentiality | Internal |
| Ingested | 2026-10-31 |

## Problem

Browser games on modest hardware stutter on first load because of unoptimised assets,
unbounded per-frame work, and simulation tied to render timing. Ember Run must stay at a
stable frame rate on a 2019-era laptop or mid-range phone and remain playable offline.

## Target user

A casual player on unreliable connectivity who expects to be playing within two seconds
of opening a link.

## Goals

1. One self-contained playable level, no install.
2. Fixed-timestep simulation that is independent of render frame rate.
3. A best score that survives reload and resists trivial forgery.
4. A first session with at most one sentence of tutorial text.

## Non-goals

Multiplayer, accounts, leaderboards, any server component, level editor, monetisation.

## Functional requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | Avatar auto-runs right and jumps on input. | Must |
| FR-2 | Obstacles spawn from a seed so a run is reproducible. | Must |
| FR-3 | Collision ends the run and shows the final score. | Must |
| FR-4 | Score accrues with distance and collected embers. | Must |
| FR-5 | Best score persists locally and shows on the start screen. | Must |
| FR-6 | Restart without a page reload. | Must |
| FR-7 | Difficulty ramps with distance to a defined ceiling. | Should |
| FR-8 | Mute toggle that persists. | Should |
| FR-9 | Touch, keyboard, and pointer input all work. | Should |

## Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Fixed 60 Hz simulation step; rendering may drop frames without changing physics. |
| NFR-2 | 8 ms steady-state frame budget; no per-frame allocation in the hot loop. |
| NFR-3 | First-load payload under 500 KB including the engine. |
| NFR-4 | No secrets, tokens, or private endpoints in client code. |
| NFR-5 | Every value read from storage is treated as untrusted and clamped. |
| NFR-6 | Correctness must not depend on `requestAnimationFrame` timing. |

## Acceptance criteria

- Fixed seed produces an identical obstacle sequence every run.
- Halving the render rate does not change simulated distance for the same inputs.
- A nonsense stored best score neither crashes the game nor grants an advantage.
- Interactive within two seconds on a throttled connection.
- No non-goal appears in the build.

## Constraints

- Browser only, static hosting, no server.
- Game code lives under `app/game/` per `docs/runbooks/game-dev.md`.
- Asset storage policy is `Proposed` in `docs/adr/0002-game-asset-storage-policy.md`.

## Open decisions

| # | Decision | Blocks | Owner | Status |
| --- | --- | --- | --- | --- |
| 1 | Engine: Phaser 4, Phaser 3, or plain Canvas | Enabling exactly one engine overlay; NFR-3 budget | Tech lead | **Decided 2026-10-31: plain Canvas 2D** |
| 2 | Asset storage for authoring masters | Committing any binary art | Tech lead | Open |
| 3 | Score authority without a server | FR-5 wording and its acceptance test | Product | **Closed 2026-10-31: local-only, "not trivially forged"** |

### Decision 3 (resolved): local scores, no proof-of-run

The PRD lists leaderboards and any server component as non-goals, so there is no
authority to appeal to and no reason to build one. FR-5's "cannot be trivially forged"
is therefore scoped honestly:

- A stored value that is not a finite, plausible number becomes **zero**, not a clamped
  ceiling — clamping would hand an attacker the best possible score.
- Nothing else is protected, and the PRD says so. A determined player can still edit
  storage to a plausible number; that is a known and accepted limit of a client-only
  game, not a defect to fix later.

Revisit only if a leaderboard enters scope, at which point the score must be confirmed
by an authoritative source rather than accepted from the client.

### Decision 1 (resolved): plain Canvas 2D

No engine overlay is enabled. The reasons, in order:

- NFR-3 budgets 500 KB for the whole first load. An engine spends a large part of that on runtime nobody asked for in a one-level game.
- Every slice so far is engine-agnostic pure logic. Canvas keeps it that way; introducing Phaser would make scene lifecycle and the loader part of every future test.
- It removes a blocking dependency: `overlay-game-phaser` and `js.phaser4` may not both be enabled, and neither is enabled now.
- Rendering is a thin adapter over `loop.js` and `player.js`, so it can be swapped later without touching gameplay logic.

Revisit only if a feature needs what Canvas does not provide cheaply — tilemaps, a particle system, or physics beyond AABB.

## Traceability

Requirements map to slices in this order. Each slice is one `build-feature` run.

| Slice | Covers | Depends on | Status |
| --- | --- | --- | --- |
| S1 Deterministic simulation core | FR-2, NFR-1, NFR-6 | Decision 1 | Delivered — `src/rng.js`, `src/loop.js`, 9 tests |
| S2 Auto-run and jump physics | FR-1 (physics half), NFR-1 | S1 | Delivered — `src/player.js`, 10 tests. Input binding still open |
| S3 Collision, scoring, run end | FR-3, FR-4 | S1, S2 | Delivered — `src/world.js`, `src/score.js`, 20 tests |
| S4 Persistence and clamping | FR-5, NFR-5 | S3, Decision 3 | Delivered — `src/storage.js`, clamping half in `score.js` |
| S5 Difficulty ramp and mute | FR-7, FR-8 | S3 | Delivered — `src/difficulty.js`, mute in `storage.js` |
| S6 Perf pass and build prep | NFR-2, NFR-3 | S1-S5 | Delivered — `src/renderer.js`, `src/main.js`, `index.html`. 26 KB shipped against a 500 KB budget |

S1 to S6 are all delivered. 65 tests pass under `cd app/game && node --test`.

**Still not delivered:** FR-9 (touch, keyboard, pointer input) has listeners wired in
`main.js` but no automated coverage, because it needs a DOM harness the starter does
not provide. Everything the tests cover is pure logic; the Canvas adapter, the input
listeners and `requestAnimationFrame` are verified by hand-loading the page, not by CI.
Treat a green suite as proof of the simulation, never of the rendering.

S1 and S2 are deliberately engine-agnostic, so they were built before Decision 1
was settled. Everything from S3 that touches rendering is blocked on it.

FR-9 (touch, keyboard, pointer) is not covered by any slice yet: it needs a DOM
harness, which the starter does not provide. Track it as S2b when an engine is
chosen and a browser-based check exists.

## Verification

`cd app/game && node --test` runs the whole application suite. A slice is only
done when that command passes and its result is recorded, not when the code
merely exists.

## Out of scope for v1

Onboarding tutorial, achievements, daily challenges, cloud saves, analytics.
