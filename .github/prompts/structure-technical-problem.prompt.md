# Structure Technical Problem

Use this prompt to apply McKinsey-style structured problem-solving to a complex or ambiguous technical challenge before starting discovery or planning work.

## Context To Inspect First

- `.github/copilot-instructions.md` and matching stack overlays under `.github/instructions/`.
- The nearest source-of-truth docs for the problem domain, such as architecture docs, ADRs, API contracts, or runbooks.
- Any existing bug reports, incident postmortems, performance data, or user feedback relevant to the problem.
- The `problem-structuring` skill at `.github/skills/problem-structuring/SKILL.md` for the full seven-step method.

## Deliverables

- A one-sentence "How to…" problem statement with clear scope boundaries.
- A MECE issue tree decomposing the problem into non-overlapping, exhaustive branches with a hypothesis per branch.
- An impact × feasibility prioritization matrix identifying the vital few issues and deferred issues.
- An analysis plan with evidence needed, methods, owners, and timeboxes for each prioritized issue.
- Findings summary per hypothesis (confirmed, refuted, or inconclusive).
- A Pyramid Principle synthesis: headline recommendation with 2–4 supporting arguments.
- An SCQA communication: Situation, Complication, Question, Answer.

## Safety Boundaries

- Do not treat hypotheses as conclusions before evidence is gathered.
- Do not let structuring become analysis paralysis — timebox each step.
- Do not fabricate data or certainty when evidence is unavailable; call out gaps explicitly.
- Do not turn this into a full implementation plan; hand off to `analyst` or `tech-planner` after structuring.
- Stop and ask before expanding scope beyond the original problem boundary.

## Expected Output

- Problem statement
- Issue tree with hypotheses
- Prioritization matrix
- Analysis plan
- Findings summary
- Pyramid synthesis
- SCQA communication
- Recommended next step and agent
