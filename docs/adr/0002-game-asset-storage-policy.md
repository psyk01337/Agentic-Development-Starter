# ADR 0002: Game Asset Storage Policy

- Status: Proposed
- Date: 2026-09-10
- Owners: Team (pending approval)
- Related: `.github/starter-modules.json`, `.github/instructions/game-assets-pipeline.instructions.md`, `.github/examples/game-dev/gitattributes.addendum`, `docs/runbooks/game-dev.md`

## Context

The starter added engine-agnostic game overlays plus a Phaser engine overlay. The asset overlay requires a boundary between authoring masters (editable source files) and runtime assets (optimized files the game loads and ships), but it deliberately does not mandate how masters are stored, because storage policy cannot be assumed by a starter that is adopted by unrelated repositories.

Three constraints make the current state untenable for adopting repos.

1. The starter's core `.gitattributes` sets `* text=auto eol=lf` for every file in every repo. Git usually detects binary content correctly, but a text-mode checkout of an asset file corrupts it, and there is no explicit guard today.
2. Large-file storage is metered. Storage and bandwidth are both limited, and every CI clone consumes the allowance again. Tracking hundreds of small runtime images as large files is a common and expensive mistake.
3. Game asset trees are binary-heavy and long-lived. Unresolvable binary merge conflicts in shared art or audio are the dominant source of lost work in game repositories.

Without a recorded decision, every adopting repo re-decides this independently, the asset overlay cannot reference a concrete policy, and CI cost stays unpredictable.

## Decision

Adopt a two-tier, directory-scoped asset model.

Authoring masters are tracked as binary content, and, where the team uses large-file storage, are tracked by directory scope rather than by file extension. Runtime assets are ordinary Git files that are regenerable from masters by a scripted, pinned, deterministic asset build.

Specifically:

- Master paths are scoped by directory, for example `app/game/assets/masters/**` and `art/**`.
- Large-file rules, where used, cover directories only. Extension-scoped rules such as `*.png` or `*.wav` are rejected as a default.
- Every large-file or binary rule ends in `-text` so the core `* text=auto eol=lf` rule stops applying to those paths.
- The core `.gitattributes` is **not** modified. Repos opt in by copying lines from `.github/examples/game-dev/gitattributes.addendum`, so non-game repos and game repos without large-file storage both keep working.
- CI jobs that do not need masters skip the download, using the skip-smudge switch for the chosen large-file system.

## Consequences

Positive outcomes

- Binary corruption from text normalization is prevented by an explicit rule rather than by Git's content heuristic.
- Large-file bandwidth is spent only on masters, and only on jobs that actually need them.
- Runtime assets stay reviewable and rebase cleanly because they are regenerated rather than hand-edited.
- The asset overlay can describe a boundary and point at a concrete addendum without assuming any tooling is configured.
- Repos that never adopt large-file storage are unaffected, so the policy stays honest to the starter's modular design.

Trade-offs and risks

- The policy is not machine-enforced. No validator can confirm a repo applied the addendum correctly, so this depends on documentation and review.
- Directory scoping requires teams to keep the masters and runtime split disciplined. A master dropped into a runtime path silently loses its rule.
- Large-file quotas, bandwidth pricing, and switch names are vendor-specific and change over time. The addendum deliberately avoids hardcoding quota numbers.
- Git LFS is not the only option; the decision names the properties that matter rather than mandating one vendor.

Operational impacts

- Adopting repos must add an `assets/masters` versus `assets/runtime` split even if both live in one repository.
- Renormalization is required once after adding the rules.
- CI workflows that only validate workflow assets or run pure-logic tests should set the skip switch.

## Options Considered

1. Extension-scoped large-file storage

- Pros
- Simple to express and easy to apply retroactively
- Catches assets regardless of where they live

- Cons
- Tracks small runtime images and audio as large files
- Consumes metered bandwidth on every CI clone
- Silently captures future files that never needed tracking

1. Directory-scoped large-file storage plus a deterministic asset build

- Pros
- Targets masters only, which is where the size and conflict risk actually live
- Keeps runtime assets rebase-friendly and reviewable
- Works with or without large-file storage enabled
- CI can skip master downloads entirely

- Cons
- Requires a documented masters/runtime split
- Requires a pinned, scripted asset build step
- Misplaced files lose their rule, so it depends on convention discipline

1. External system of record for masters

- Pros
- Keeps the repository small regardless of asset volume
- Scales to multi-gigabyte source art and non-Git-fluent art teams

- Cons
- The repository is no longer the complete source of truth, which conflicts with the starter's repo-native premise
- Introduces backup, access, and retention obligations outside the repo
- Harder for an agent to verify asset provenance

1. No large-file storage, explicit binary markers only

- Pros
- Simplest possible setup
- No vendor dependency or metered cost

- Cons
- Repository size grows without bound as art accumulates
- Clones and CI slow down permanently
- Practical only for small asset trees

## Rollout Plan

1. Ship the addendum as an example only, keeping the core `.gitattributes` unchanged. (Done.)
2. Reference the addendum from the asset overlay and the game runbook so it is discoverable. (Done.)
3. Record this decision and obtain approval before treating it as accepted.
4. When a real game repo adopts the overlays, apply the addendum, renormalize once, and verify attribute resolution on a representative asset.
5. Add a CI note to the game runbook or CI overlay describing the skip switch rather than editing workflow files in this repo.
6. Do not add a validator that enforces this policy; enforcement would require assuming a specific tool.

## Validation

Verify the decision works by:

- Confirming `git check-attr text eol filter` on a master path and on a runtime path returns the expected values after applying the addendum.
- Confirming a clean clone with the skip switch set does not download masters while the game still loads.
- Confirming the runtime assets regenerate byte-identically from masters using the pinned asset build.
- Confirming the core `.gitattributes` still contains only its original rules, so non-game repos are unaffected.

## Follow-up

- Review trigger: the first time a real game repo adopts the overlays, or any change to the core `.gitattributes`, whichever comes first.
- Revisit if a repo's asset volume makes the repository itself the wrong home for masters, which would move it to option 3.
- Revisit if the chosen large-file vendor changes its metering model or its skip-switch name.
- This ADR stays `Proposed` until a maintainer accepts it; until then the addendum is the only concrete artifact and no repo is bound by it.
