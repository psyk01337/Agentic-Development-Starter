# Vendored: pstack

Selected skills from [cursor/plugins pstack](https://github.com/cursor/plugins/tree/main/pstack),
copyright (c) 2026 Lauren Tan, MIT licensed. The upstream licence is reproduced verbatim at
[LICENSE](./LICENSE) and summarised in the repository root `THIRD_PARTY_NOTICES.md`.

## What Is Here

Twenty-eight skills, unmodified: the twenty-four `principle-*` skills and the four
verification-skill lifecycle skills (`create-` / `maintain-verification-skill`, plus the
`formal` variants).

## What Is Not Here

The other upstream skills, the two agents, and the `automations/` tree. They are not
vendored because this starter already carries 34 skills of its own; importing the remainder
would leave roughly ninety skills with no navigation and no owner. The lifecycle skills are
included because they encode the one thing this repository lacks: a procedure for turning an
escaped defect into a permanent check.

## This Directory Is Inert

Nothing under `vendor/` is loaded by the agent host, executed, or validated against this
repository's skill contracts. That is deliberate:

- **Upgrades stay mechanical.** Re-fetching upstream replaces files with no three-way merge.
- **Foreign prose is not held to local style.** `check-markdown-quality` excludes `vendor/`,
  because rewriting third-party text to satisfy our lint defeats the point of vendoring it.
- **Provenance stays obvious.** A reader can tell what is ours from what is borrowed.

To make a vendored skill active, copy the directory into `.github/skills/` and register it in
`.github/starter-modules.json`. Copying is a deliberate act per skill, not a bulk import,
because an active skill is a claim this repository is prepared to maintain.

## Updating

Re-run the fetch against `main` and diff; do not hand-edit the contents. If upstream changes a
principle, that difference is worth reading, not silently absorbing.