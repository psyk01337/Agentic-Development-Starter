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

| # | Decision | Blocks | Owner |
| --- | --- | --- | --- |
| 1 | Engine: Phaser 4, Phaser 3, or plain Canvas | Enabling exactly one engine overlay; NFR-3 budget | Tech lead |
| 2 | Asset storage for authoring masters | Committing any binary art | Tech lead |
| 3 | Score authority without a server | FR-5 wording and its acceptance test | Product |

Decision 1 must be settled before any `app/game/src` code is written, because a wrong
choice costs a rewrite and because only one engine overlay may be enabled at a time.

## Traceability

Requirements map to slices in this order. Each slice is one `build-feature` run.

| Slice | Covers | Depends on | Status |
| --- | --- | --- | --- |
| S1 Deterministic simulation core | FR-2, NFR-1, NFR-6 | Decision 1 | Delivered — `src/rng.js`, `src/loop.js`, 9 tests |
| S2 Auto-run and jump physics | FR-1 (physics half), NFR-1 | S1 | Delivered — `src/player.js`, 10 tests. Input binding still open |
| S3 Collision, scoring, run end | FR-3, FR-4 | S1, S2 | Not started |
| S4 Persistence and clamping | FR-5, NFR-5 | S3, Decision 3 | Not started |
| S5 Difficulty ramp and mute | FR-7, FR-8 | S3 | Not started |
| S6 Perf pass and build prep | NFR-2, NFR-3 | S1-S5 | Not started |

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
