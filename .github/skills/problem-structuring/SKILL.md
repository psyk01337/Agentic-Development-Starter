---
name: problem-structuring
description: Apply structured problem-solving (MECE decomposition, hypothesis-driven analysis, issue prioritization, Pyramid Principle synthesis, and SCQA communication) to complex or ambiguous technical challenges before design or implementation.
---
# Skill: problem-structuring

## When to Use
Use this skill when a technical problem, design decision, or feature request is too complex or ambiguous to jump straight into discovery or planning. It is the bridge between "we have a vague problem" and "we have a structured, prioritised plan."

This skill adapts the McKinsey 7-step problem-solving method for software engineering contexts. It is not a general-purpose consulting framework — it is a bounded, repeatable playbook for structuring technical problems before the `analyst` → `tech-planner` chain begins.

## Trigger Examples
- "Structure this problem before we start investigating."
- "Decompose this feature request into addressable parts using MECE."
- "Apply hypothesis-driven analysis to this performance issue."
- "Synthesize these findings using the Pyramid Principle."
- "Frame this technical decision using SCQA."

## The Seven Steps (Adapted for Software)

### 1. Define the Problem
Frame the problem as a single "How to…" statement with clear boundaries.
- What is the observed gap between current state and desired state?
- Who or what is affected? What is the measurable impact?
- What is in scope and out of scope?
- Write a one-sentence problem statement: *"How to [achieve outcome] given [constraints]?"*

### 2. Structure the Problem (MECE)
Decompose the problem into mutually exclusive, collectively exhaustive (MECE) components.
- Build an issue tree: start with the core question, then branch into sub-questions.
- Each branch must be MECE — no overlap, no gaps.
- For software problems, common decomposition axes: system layers, user journeys, data flow stages, component boundaries, or failure modes.
- Form an initial hypothesis for each branch: *"I believe X is the root cause because Y."*

### 3. Prioritize Issues
Use an impact × feasibility matrix to focus on the vital few.
- Rate each issue branch on: impact if solved (high/medium/low) and ease of resolution (high/medium/low).
- Apply the 80/20 rule: which 20% of issues drive 80% of the observed problem?
- Identify "quick wins" (high impact, high feasibility) and deprioritize low-impact branches.
- State which issues are deferred and why.

### 4. Plan Analyses and Workplan
Define what data is needed, how to get it, and who owns each analysis.
- For each prioritized issue: what evidence would confirm or refute the hypothesis?
- What is the cheapest, fastest way to get that evidence? (Log query? Code search? Reproduce locally? Talk to a team member?)
- Assign owners and timeboxes. Prefer hours over days for individual analyses.
- Identify dependencies between analyses.

### 5. Conduct Analyses
Test each hypothesis against evidence. Avoid analysis paralysis.
- Gather only the data needed to confirm or refute the hypothesis.
- If data is unavailable, state what proxy evidence exists and its limitations.
- Record results: confirmed, refuted, or inconclusive.
- Stop when the remaining uncertainty no longer changes the recommended next step.

### 6. Synthesize Findings (Pyramid Principle)
Structure findings top-down: answer first, then supporting arguments.
- Lead with the headline recommendation.
- Support with 2–4 key arguments, each backed by evidence from the analyses.
- Use the "governing thought" pattern: *"We should [action] because [reason 1], [reason 2], and [reason 3]."*
- Call out residual uncertainty and its materiality to the recommendation.

### 7. Communicate Recommendations (SCQA)
Structure the final output using Situation, Complication, Question, Answer.
- **Situation**: the stable context everyone agrees on.
- **Complication**: what changed or what is at stake.
- **Question**: the explicit question the analysis answers.
- **Answer**: the recommendation, with supporting evidence and tradeoffs.

## Output Format (Strict)
Produce sections in this exact order:

1. Problem Statement
   - One-sentence "How to…" framing with scope boundaries.

2. Issue Tree (MECE)
   - Top-level branches with sub-questions. State the hypothesis for each branch.

3. Prioritization Matrix
   - Impact × feasibility rating for each branch. Which issues are deferred and why.

4. Analysis Plan
   - For each prioritized issue: hypothesis, evidence needed, method, owner, timebox.

5. Findings Summary
   - Per hypothesis: confirmed, refuted, or inconclusive. Key evidence.

6. Pyramid Synthesis
   - Headline recommendation. 2–4 supporting arguments with evidence.

7. SCQA Communication
   - Situation, Complication, Question, Answer in explicit paragraphs.

8. Recommended Next Step
   - The smallest safe next action and which agent should take it.

## Safety Notes
- Do not treat hypotheses as conclusions before evidence is gathered.
- Do not let the framework become analysis paralysis — timebox each step.
- If data is unavailable, say so explicitly rather than fabricating proxy certainty.
- Keep the output concise; this is a structuring tool, not a replacement for discovery or planning.
