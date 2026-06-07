---
name: memory-curation
description: Review candidate agent memories and decide what belongs in session memory, repo truth, or optional durable memory.
---
# Skill: memory-curation

## When to Use
Use this skill when an agent wants to save a lesson learned, team preference, repeated workflow pattern, or long-running project context.

## Inputs Expected
- Candidate memory text.
- Scope: current task, repository, team, or user preference.
- Sensitivity assessment.
- Related repo source-of-truth files.
- Retention or pruning expectation.

## Procedure
1. Classify the candidate into session memory, repo truth, optional durable memory, or do not store.
2. Reject secrets, credentials, customer private data, raw production logs, and regulated data by default.
3. Prefer repo truth for durable project decisions, policies, contracts, and runbooks.
4. Keep optional durable memory scoped to stable non-sensitive preferences and repeated patterns.
5. Record pruning or review instructions when durable memory is appropriate.

## Output Format
- Candidate memory
- Recommended layer
- Reason
- Source-of-truth file to update, if any
- Sensitivity notes
- Retention or pruning guidance

## Verification Checklist
- The recommendation follows the three-layer memory strategy.
- The memory does not contain secrets or sensitive data.
- Repo truth is preferred for durable project facts.
- Optional durable memory is scoped and reviewable.

## Safety Notes
- Never store secrets, API keys, passwords, private customer data, or production credentials.
- Do not let Honcho or another memory provider become authoritative over repo files.
- Stop and ask before storing anything that may be regulated or confidential.

## Referenced Scripts Or Resources
- `.github/instructions/memory.instructions.md`
- `docs/runbooks/memory-strategy.md`
- `.github/examples/memory/honcho-policy.example.md`