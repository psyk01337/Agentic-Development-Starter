# Golden Task: Problem Structuring

## Scenario

A complex, ambiguous technical problem has been raised. The problem spans multiple system layers, has unclear root causes, and affects several teams. The agent must apply fact-based, hypothesis-driven structured problem-solving (initial hypothesis, MECE decomposition, key-driver focus, intuition-data balance, Pyramid Principle synthesis, and SCQA communication with buy-in) before any implementation work begins.

## Instructions To Agent

1. Read the repo baseline instructions first.
2. Read the `problem-structuring` skill at `.github/skills/problem-structuring/SKILL.md`.
3. Frame the problem as a single "How to…" statement with scope boundaries, business need, and an initial hypothesis (the one-day answer).
4. Build a MECE issue tree that tests the initial hypothesis. Identify likely key drivers.
5. Prioritize issues using an impact × feasibility matrix. Highlight key drivers. Call out deferred issues and why.
6. Design analyses for each prioritized issue: hypothesis to test, evidence that would confirm/refute, method, owner, timebox, dependencies, and fallback if inconclusive.
7. Gather evidence and classify each piece as data-backed, intuition-backed, or assumption. Note gaps and proxies.
8. Interpret results: mark each hypothesis confirmed/refuted/inconclusive, apply the "so what?" test, and revisit the initial hypothesis.
9. Synthesize using the Pyramid Principle: headline recommendation with 2–4 supporting arguments and evidence classification.
10. Communicate using SCQA with audience-specific buy-in considerations and an explicit decision ask.
11. Produce a handoff with the structured output and a recommended next agent.

## Unsafe Shortcuts To Avoid

- Jumping to a solution before forming an initial hypothesis or structuring the problem.
- Treating hypotheses as conclusions without evidence classification.
- Presenting intuition as fact — label intuition-backed claims explicitly.
- Skipping prioritization and trying to analyze everything equally.
- Gathering "interesting but irrelevant" data that does not address a prioritized question.
- Fabricating evidence when data is unavailable — use the best proxy and note the gap.
- Letting the framework become analysis paralysis — use the one-day answer and timebox each step.
- Omitting the "so what?" — listing findings without connecting them to the decision.
- Turning structuring into a full implementation plan.
