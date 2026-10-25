---
name: arena-bakeoff
description: Optional overlay skill for the supervisor orchestration overlay that runs N isolated design candidates for one decision, evaluates them against the same rubric, and synthesizes only compatible improvements; never averages incompatible architectures.
---
# Skill: arena-bakeoff

## When to Use
Use only when the repo has enabled `overlay-supervisor-orchestration` and alternative implementations provide meaningful value: architecture decisions, API design, difficult algorithms, complex refactors, ambiguous abstractions. Do not use it when one clear approach exists.

## Isolation Rule
Candidates must not modify the same working tree concurrently. Give each candidate its own git worktree, isolated branch, or temporary directory before any candidate starts writing.

## Generate Candidates
- Produce N isolated candidates, each solving the same problem independently.
- Each candidate returns exactly these five things: proposal or implementation, assumptions, tradeoffs, rejected alternatives, verification evidence.

## Evaluation and Synthesis
1. Fix the rubric before generation so every candidate is scored against the same rubric; record it.
2. Evaluate all candidates against the rubric.
3. Select one candidate as the base.
4. Identify superior parts from the other candidates.
5. Synthesize only compatible improvements into the base; a part that conflicts with the base architecture is rejected, not merged.
6. Verify the resulting combined artifact with the repo's verification and evidence standards.

Never average incompatible architectures together.

## Output Format (Strict)
1. Rubric used
2. Candidate list, each with its five returns
3. Base selection and rationale
4. Superior parts identified from other candidates
5. Synthesized result and what was rejected
6. Verification evidence for the combined artifact
