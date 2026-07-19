# Expected Behavior Checklist: Problem Structuring

Use this checklist to evaluate whether the agent followed the problem-structuring workflow correctly.

## Core Principles

- [ ] Fact-based, hypothesis-driven discipline is applied — hypotheses are formed early, then tested.
- [ ] Intuition-data balance is explicit — claims are classified as data-backed, intuition-backed, or assumption.
- [ ] One-day answer is stated — a preliminary best guess before deep analysis.
- [ ] Key drivers are identified — the vital few factors, not an exhaustive enumeration.

## Problem Statement

- [ ] Problem is framed as a single "How to…" statement.
- [ ] Scope boundaries (in-scope and out-of-scope) are explicit.
- [ ] The affected parties and measurable impact are stated.
- [ ] Constraints are listed.
- [ ] Initial hypothesis is stated: "My best guess at the answer is…"
- [ ] Business need driving the problem is identified (competitive, organizational, financial, or operational).

## Issue Tree (MECE)

- [ ] The core question is decomposed into branches.
- [ ] Branches are mutually exclusive (no overlap).
- [ ] Branches are collectively exhaustive (no gaps).
- [ ] Decomposition axes are appropriate for the problem domain.
- [ ] Likely key drivers are identified among the branches.
- [ ] Each branch is tied to testing the initial hypothesis.

## Prioritization

- [ ] Each issue branch has an impact rating (high/medium/low).
- [ ] Each issue branch has a feasibility rating (high/medium/low).
- [ ] Key drivers are highlighted and prioritized.
- [ ] The 80/20 rule is applied — which 20% drive 80% of the problem?
- [ ] Deferred issues are listed with a reason for deferral.
- [ ] Quick wins (high impact, high feasibility) are identified.

## Analysis Design

- [ ] Each prioritized issue has a stated hypothesis to test.
- [ ] Evidence that would confirm the hypothesis is specified.
- [ ] Evidence that would refute the hypothesis is specified.
- [ ] Method for gathering evidence is the cheapest feasible option.
- [ ] Analyses are designed to produce yes/no/inconclusive results.
- [ ] Owner is assigned (even if TBD with a reason).
- [ ] Timebox is set (hours, not days).
- [ ] Dependencies between analyses are identified.
- [ ] Fallback is stated for each analysis if it comes back inconclusive.

## Evidence Gathered

- [ ] Per hypothesis: evidence collected, source, and reliability are recorded.
- [ ] Each piece of evidence is classified: data-backed, intuition-backed, or assumption.
- [ ] Only evidence that addresses prioritized questions is gathered — no "interesting but irrelevant" data.
- [ ] Data gaps are called out explicitly with the best available proxy.
- [ ] Proxy evidence limitations are stated when applicable.
- [ ] Gathering stops when additional data would not change the recommended action.

## Interpretation

- [ ] Each hypothesis is marked: confirmed, refuted, or inconclusive.
- [ ] Refuted hypotheses include what was learned.
- [ ] Inconclusive hypotheses state what missing data would resolve uncertainty and whether obtaining it is worth the cost.
- [ ] Patterns across hypotheses are identified.
- [ ] "So what?" test is applied — each finding is tied to the decision at hand.
- [ ] Initial hypothesis from Step 1 is revisited: confirmed, refined, or replaced?

## Pyramid Synthesis

- [ ] Headline recommendation is stated first.
- [ ] 2–4 supporting arguments are provided.
- [ ] Each argument is backed by evidence from the analyses with evidence classification.
- [ ] "Governing thought" pattern is used: "We should [action] because [reasons]."
- [ ] Residual uncertainty is stated with its materiality to the recommendation.

## SCQA Communication

- [ ] Situation paragraph describes stable, agreed-upon context.
- [ ] Complication paragraph describes what changed or is at stake.
- [ ] Question is the explicit question the analysis answers — maps to Step 1 problem statement.
- [ ] Answer is the recommendation with supporting evidence and tradeoffs.
- [ ] Audience-specific buy-in considerations are addressed.
- [ ] Hardest objection is pre-empted in the narrative.
- [ ] Decision ask is explicit: who needs to decide what by when.

## Handoff

- [ ] Recommended next step is the smallest safe action.
- [ ] Recommended next agent is named with a reason.
- [ ] Decision status is stated.
- [ ] Blockers or approvals needed are listed.

## Red Flags (Automatic Failure)

- [ ] No problem statement — the problem is never defined.
- [ ] No initial hypothesis — the agent gathers data without forming a preliminary answer.
- [ ] No issue tree — the problem is never decomposed.
- [ ] Hypotheses treated as conclusions without evidence or without classification as intuition-backed.
- [ ] Evidence fabricated when data is unavailable — no proxy or gap acknowledged.
- [ ] All issues treated as equal priority (no prioritization or key-driver focus applied).
- [ ] Intuition presented as fact — intuition-backed claims not labeled explicitly.
- [ ] Analysis paralysis — structuring takes precedence over actionable next steps.
- [ ] No "so what?" — findings listed without connection to the decision.
- [ ] Framework applied mechanically without adapting to the problem domain.
