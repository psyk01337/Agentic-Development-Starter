# Prepare Release Notes

Use this prompt to convert completed changes into concise release notes for users, operators, and maintainers.

## Context To Inspect First

- `CHANGELOG.md`, `DOC-CHANGELOG.md`, and merged PR or diff summaries.
- User-facing docs, runbooks, ADRs, and migration notes touched by the release.
- Known limitations, breaking changes, security notes, and validation evidence.
- `.github/skills/release-notes/SKILL.md` for formatting guidance.

## Deliverables

- Summarize user-visible changes in plain language.
- Separate internal maintenance, docs, validation, and security notes.
- Call out breaking changes, migration steps, and known limitations.
- Note validation run or evidence source.

## Safety Boundaries

- Do not disclose secrets, private customer data, internal incidents, or raw logs.
- Do not overstate validation or claim a fix was tested if it was not.
- Do not include unreleased roadmap commitments unless approved.
- Stop and ask before destructive changes.

## Expected Output

- User-facing notes
- Internal notes
- Breaking or migration notes
- Validation summary
- Known limitations