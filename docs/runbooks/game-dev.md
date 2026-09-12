# Game Development Runbook

Use this runbook when composing the starter for a browser game repository, or when working inside game code under `app/game/`.

The first supported engine is Phaser. The engine-agnostic overlays apply to any engine; the engine overlay is what changes.

## 1) Compose The Game Overlays

Add or keep the engine-agnostic game overlays:

- `.github/instructions/gameplay-systems.instructions.md`
- `.github/instructions/game-performance.instructions.md`
- `.github/instructions/game-assets-pipeline.instructions.md`

If the repo uses Phaser, also add:

- `.github/instructions/phaser.instructions.md`

Keep engine-agnostic game rules in the engine-agnostic overlays, and keep engine-specific rules (scene lifecycle, loader, scale manager, physics options) in the engine overlay. See [Starter Composition](starter-composition.md) for the general overlay rules.

## 2) Use The `app/game/` Convention

Game code and assets live under `app/game/`, alongside the other application code described in [Starter Adoption](starter-adoption.md).

```
app/game/
  assets/
    masters/    # editable sources: project files, layered art, uncompressed audio
    runtime/    # optimized files the game loads and ships
  src/          # game code
  tests/        # pure-logic tests
```

Rules:

- Game overlays are scoped by path, not by file extension, so they never attach to non-game TypeScript or JavaScript.
- Inside `app/game/`, the engine overlay takes precedence over a React or Next.js overlay.
- The `masters/` and `runtime/` split is what makes the asset storage decision reviewable; keep it even if both live in the same repository.

## 3) Decide Asset Storage Before Committing Art

Asset storage is a repo-specific decision with a starter-wide default of "not configured". Read [.gitattributes addendum](../../.github/examples/game-dev/gitattributes.addendum) and [.gitignore addendum](../../.github/examples/game-dev/gitignore.addendum) before adding binary assets.

The two decisions to make:

1. Where authoring masters live: repository large-file storage, or an external system of record.
2. Which paths are treated as binary versus text.

Two constraints drive the answer:

- Git's default text normalization must never touch binary assets, or the files are corrupted on checkout.
- Large-file storage is metered. Tracking hundreds of small runtime images there is expensive and slows every CI clone.

A workable default is directory-scoped: masters tracked as binary/large-file, runtime assets as ordinary files. Confirm the current quotas and limits in the official documentation for whichever large-file system you choose before committing to it.

### CI Consequence

CI jobs that only validate workflow assets or run pure-logic tests should not download asset masters. Set the skip-download switch for the large-file system you use on those jobs. For Git LFS the conventional setting is `GIT_LFS_SKIP_SMUDGE=1`; verify the current variable name in the official Git LFS documentation.

## 4) Work With The Right Prompt

- Design a subsystem first: `design-game-system.prompt.md`.
- Implement one mechanic as a small slice: `implement-game-mechanic.prompt.md`.
- Diagnose frame drops or memory growth: `profile-game-performance.prompt.md`, or the `game-perf-triage` skill.
- Prepare a shippable build: `prepare-game-build.prompt.md`.

See [Skills](skills.md) for the `game-perf-triage` triggers.

## 5) Respect The Client Trust Boundary

In a browser game, everything the client computes is attacker-controlled. This is the highest-risk area in game code and it is not covered by the generic security baseline in a game-specific way.

- Scores, unlocks, currency, drop rates, and timers that matter must be confirmed by an authoritative source, not accepted from the client.
- Never ship API keys, service tokens, or private endpoints in client code or assets. Anything sent to the browser is public.
- Validate and clamp every value read back from `localStorage` or `sessionStorage` and treat a save file as untrusted input.
- Sanitize player-supplied text before it touches the DOM; prefer rendering text on the canvas.

## 6) Validate Workflow Assets After Edits

When a task edits game instructions, prompts, skills, or this runbook, run the starter checks before closing the task.

- PowerShell: `.github/scripts/check-starter-workflow.ps1`
- Shell: `.github/scripts/check-starter-workflow.sh`

## 7) Record Durable Decisions

Record these in an ADR under `docs/adr/` when they are settled, because each affects every game repo adopting the starter:

- Asset storage and large-file policy for masters. The current proposal is recorded in `docs/adr/0002-game-asset-storage-policy.md` and is `Proposed`, not yet binding.
- Whether the engine overlay stays Phaser-only or gains siblings for other engines.
- Any change to the fixed-timestep or save-versioning contract.

## When Not To Use These Overlays

- When the repo has no game code, or the "game" is a static mockup; use the static prototype overlay instead.
- When the work is ordinary web UI that happens to sit near a game; use the frontend overlay.
- When a prototype is throwaway and speed matters more than determinism, saves, or budget discipline.
