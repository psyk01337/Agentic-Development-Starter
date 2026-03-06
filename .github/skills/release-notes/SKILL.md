---
name: release-notes
description: Convert merged technical changes into concise user-facing and internal release notes.
---
# Skill: release-notes

## When to Use
Use this skill after merges or before a release cut to summarize meaningful changes.

## Trigger Examples
- "Draft release notes from the last merged PRs."
- "Create user and internal notes for this sprint release."
- "Summarize what shipped this week."

## Checklist
- Group changes by user-facing impact and internal engineering impact.
- Highlight breaking changes, migrations, and rollout/rollback notes.
- Include bug fixes with observable behavior changes.
- Keep language concise and non-ambiguous.
- Exclude secrets/internal-only sensitive details from public notes.

## Output Format (Strict)
Produce sections in this exact order:
1. User-Facing Notes
- Bulleted highlights understandable by end users.
2. Internal Notes
- Technical details, migrations, ops considerations.
3. Upgrade Notes
- Required actions, flags, or `None`.
4. Verification
- High-level checks performed after release.
