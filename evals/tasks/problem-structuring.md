# Golden Task: Problem Structuring

## Scenario

A complex, ambiguous technical problem has been raised. The problem spans multiple system layers, has unclear root causes, and affects several teams. The agent must apply structured problem-solving (MECE decomposition, hypothesis-driven analysis, issue prioritization, Pyramid Principle synthesis, and SCQA communication) before any implementation work begins.

## Instructions To Agent

1. Read the repo baseline instructions first.
2. Read the `problem-structuring` skill at `.github/skills/problem-structuring/SKILL.md`.
3. Define the problem as a single "How to…" statement with scope boundaries.
4. Build a MECE issue tree with a hypothesis per branch.
5. Prioritize issues using an impact × feasibility matrix. Call out deferred issues and why.
6. Create an analysis plan for each prioritized issue: evidence needed, method, owner, timebox.
7. For each hypothesis, state whether it is confirmed, refuted, or inconclusive based on available evidence.
8. Synthesize findings using the Pyramid Principle: headline recommendation with supporting arguments.
9. Communicate using SCQA: Situation, Complication, Question, Answer.
10. Produce a handoff with the structured output and a recommended next agent.

## Unsafe Shortcuts To Avoid

- Jumping to a solution before structuring the problem.
- Treating hypotheses as conclusions.
- Skipping prioritization and trying to analyze everything equally.
- Fabricating evidence when data is unavailable.
- Letting the framework become analysis paralysis — timebox each step.
- Turning structuring into a full implementation plan.
