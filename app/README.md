# Application Source

Everything the product actually does lives here. The rest of the repository is the workflow layer that governs how it gets built: instructions in `.github/instructions/`, roles in `.github/agents/`, playbooks in `.github/skills/`, and decisions in `docs/`.

Keep the split clean. Do not put workflow assets in this folder, and do not put application code outside it.

## Layout

Pick one shape and stay with it. `../docs/runbooks/starter-adoption.md` documents both patterns.

Multi-stack:

```text
app/
  frontend/     # React, Next.js, Vue, Svelte
  backend/      # FastAPI, Express, Django, Laravel
```

Single-stack:

```text
app/
  src/          # application source
  tests/        # application tests
```

The starter does not enforce either layout, and `app/` is only a default. Rename it to `src/` or `services/` if that fits the project better.

## Tell The Next Agent How To Verify

The single most useful thing in this file is the command that proves the application works. An agent landing in `app/` otherwise has to guess, and guessing is how unverified work gets reported as done.

Replace this block with the project's real commands:

```bash
# app checks - replace with the real ones
python3 -m unittest discover -s app/tests -t .
```

Rules that matter for those commands:

- Add or update the tests for the changed behavior and the most important failure path, not just the happy path.
- Run the focused check first, then the narrower starter checks in the repository root.
- Report the command and its result. A check that did not run is `NOT_VERIFIED`, never a pass.

If there is more than one toolchain, add a single entry point such as `scripts/test-all.sh` and point this file at it. Two commands nobody remembers is worse than one command everybody runs.

## What The Starter Does And Does Not Do Here

| Concern | Covered |
| --- | --- |
| `core`, `security`, and `memory` rules | yes, on every request |
| Trailing whitespace and broken relative links in this file | yes, `check-markdown-quality` scans every `*.md` |
| Which application files are registered as starter assets | no, `app/` is outside the module manifest |
| Your application's tests, lint, and build | no, only the application can define these |

That last row is the important one. The starter validates its own workflow assets, never your product. A green umbrella run says the governance layer is intact; it says nothing about whether the app builds.

## Path-Keys Instruction Overlays

Several optional overlays activate by path, so where you put a file changes which rules load with it. All of them are disabled by default, so this only matters once you enable one.

| Path | Overlay that keys off it |
| --- | --- |
| `app/game/**` | `phaser`, `js.phaser4`, `gameplay-systems`, `game-performance`, `game-assets-pipeline`, `go.gamedev` |
| `app/Http/`, `app/Jobs/`, `app/Livewire/`, `app/Filament/` | `laravel`, `livewire`, `filament`, `inertia`, `valkey` |
| `**/*.{ts,tsx,js,jsx}` anywhere | `frontend`, `react`, `nextjs` |
| `**/*.{py,pyi}` anywhere | `backend`, `fastapi` |

Two consequences worth knowing:

- `phaser.instructions.md` and `js.phaser4.instructions.md` share the same glob. Enable exactly one.
- The Laravel paths are a real collision risk. A non-Laravel project that happens to create `app/Http/` will pull in the Laravel and Inertia overlays if those modules are enabled. Check `.github/starter-modules.json` before adopting a folder name with framework meaning.

Enable overlays only for stacks the project actually uses. Each one costs context on every request that matches it.

## Conventions Worth Keeping

- `.sh` files must use LF line endings, not CRLF. Git Bash fails on CRLF with a confusing `set: pipefail: invalid option name`.
- Git Bash does not apply Windows `PATHEXT`, so `node` may not resolve there even when PowerShell finds it. Use `command -v node || command -v node.exe` in shell scripts that call it.
- Do not commit dependencies, build output, or local state. Add the toolchain's ignore paths to the repository `.gitignore`.
- Keep secrets out of this folder entirely. No `.env` with real credentials, no keys, no tokens in fixtures.

## Where To Read Next

- `../QUICKSTART.md` for the first-feature path.
- `../docs/runbooks/agentic-dev.md` for the daily loop.
- `../docs/runbooks/starter-adoption.md` for the clone-as-template guidance.
- `../.github/instructions/` for the rules that actually apply to the files here.