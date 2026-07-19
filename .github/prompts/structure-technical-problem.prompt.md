# Structure Technical Problem

Use this prompt to apply McKinsey-style fact-based, hypothesis-driven problem-solving to a complex or ambiguous technical challenge before starting discovery or planning work. Incorporates lessons from *The McKinsey Mind* (Rasiel & Friga).

## Context To Inspect First

- `.github/copilot-instructions.md` and matching stack overlays under `.github/instructions/`.
- The nearest source-of-truth docs for the problem domain, such as architecture docs, ADRs, API contracts, or runbooks.
- Any existing bug reports, incident postmortems, performance data, or user feedback relevant to the problem.
- The `problem-structuring` skill at `.github/skills/problem-structuring/SKILL.md` for the full seven-step method with core principles.

## Deliverables

- A one-sentence "How to…" problem statement with scope boundaries, business need, and an initial hypothesis (the one-day answer).
- A MECE issue tree decomposing the problem into non-overlapping, exhaustive branches that test the initial hypothesis, with key drivers identified.
- An impact × feasibility prioritization matrix highlighting key drivers and deferred issues with reasons.
- An analysis design for each prioritized issue: hypothesis to test, evidence that would confirm/refute, method, owner, timebox, dependencies, and fallback.
- Evidence gathered with classification: data-backed, intuition-backed, or assumption. Data gaps and proxies noted.
- Interpretation per hypothesis (confirmed, refuted, or inconclusive) with "so what?" connections to the decision and a revisited initial hypothesis.
- A Pyramid Principle synthesis: headline recommendation with 2–4 supporting arguments and evidence classification.
- SCQA communication: Situation, Complication, Question, Answer, with audience-specific buy-in considerations and an explicit decision ask.

## Safety Boundaries

- Form an initial hypothesis early — do not wait for all data before forming an opinion.
- Classify every claim as data-backed, intuition-backed, or assumption. Never present intuition as fact.
- Do not let structuring become analysis paralysis — use the one-day answer and timebox each step.
- Do not fabricate data or certainty when evidence is unavailable; use the best proxy and call out the gap.
- Apply the "so what?" test — deprioritize findings that do not change the recommended action.
- Do not turn this into a full implementation plan; hand off to `analyst` or `tech-planner` after structuring.
- Stop and ask before expanding scope beyond the original problem boundary.

## Expected Output

- Problem statement with initial hypothesis and business need
- Issue tree with key drivers
- Prioritization matrix
- Analysis design
- Evidence gathered (with classification)
- Interpretation (with "so what?")
- Pyramid synthesis
- SCQA communication with buy-in and decision ask
- Recommended next step and agent
