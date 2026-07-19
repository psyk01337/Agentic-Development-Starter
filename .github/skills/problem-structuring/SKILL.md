---
name: problem-structuring
description: Apply structured problem-solving (fact-based and hypothesis-driven analysis, MECE decomposition, issue prioritization, key-driver focus, Pyramid Principle synthesis, and SCQA communication) to complex or ambiguous technical challenges before design or implementation.
---
# Skill: problem-structuring

## When to Use
Use this skill when a technical problem, design decision, or feature request is too complex or ambiguous to jump straight into discovery or planning. It is the bridge between "we have a vague problem" and "we have a structured, prioritised plan."

This skill adapts McKinsey's fact-based, hypothesis-driven problem-solving method for software engineering contexts, incorporating lessons from *The McKinsey Mind* (Rasiel & Friga). It is not a general-purpose consulting framework — it is a bounded, repeatable playbook for structuring technical problems before the `analyst` → `tech-planner` chain begins.

## Trigger Examples
- "Structure this problem before we start investigating."
- "Decompose this feature request into addressable parts using MECE."
- "Apply hypothesis-driven analysis to this performance issue."
- "Synthesize these findings using the Pyramid Principle."
- "Frame this technical decision using SCQA."

## Core Principles

These cross-cutting principles apply throughout all seven steps.

### Fact-Based, Hypothesis-Driven
Every step balances two disciplines: form a hypothesis early (what you believe the answer is), then gather facts to prove or disprove it. Do not wait for all the data before forming an opinion, and do not treat an untested hypothesis as truth.

### Intuition ↔ Data Balance
Rarely will you have all the facts needed to reach certainty. When data is unavailable, use intuition tempered by experience — but label it explicitly. Categorize each claim as:
- **Data-backed**: supported by observable evidence (logs, metrics, code, repro steps).
- **Intuition-backed**: based on experience or pattern recognition, not yet confirmed.
- **Assumption**: a working belief with no direct support; must be tested at the earliest opportunity.

A sound decision balances both. If the residual uncertainty is material to the recommendation, say so — do not fabricate certainty.

### One-Day Answer
Before deep analysis, ask: *"What is my best preliminary answer after one day of thinking?"* This forces early hypothesis formation, prevents analysis paralysis, and gives the team a starting point to test against. The one-day answer will be wrong in detail — that is expected. Its purpose is to start the iteration, not to be final.

### Key Drivers
Focus on the vital few factors that explain most of the outcome. The goal of structuring is not to enumerate every possible cause — it is to identify the key drivers. If a branch of your issue tree does not materially change the recommended action, deprioritize or drop it.

## The Seven Steps (Adapted for Software)

### 1. Frame the Problem
Define the boundaries and form an initial top-level hypothesis before decomposition.
- What is the observed gap between current state and desired state?
- Who or what is affected? What is the measurable impact?
- What is in scope and out of scope?
- Write a one-sentence problem statement: *"How to [achieve outcome] given [constraints]?"*
- **Form your initial hypothesis**: *"My best guess at the answer is X, because Y."* This hypothesis will be tested, refined, or replaced as you work through the remaining steps. State your one-day answer even if you have low confidence.
- Identify the **business need** driving the problem: competitive pressure, organizational friction, financial impact, or operational failure.

### 2. Structure the Problem (MECE)
Decompose the problem into mutually exclusive, collectively exhaustive (MECE) components. The issue tree exists to **test your initial hypothesis**, not just to catalog possibilities.
- Build an issue tree: start with the core question, then branch into sub-questions.
- Each branch must be MECE — no overlap, no gaps.
- For software problems, common decomposition axes: system layers, user journeys, data flow stages, component boundaries, or failure modes.
- For each branch, ask: *"If this branch were true, would it explain the observed problem? What evidence would confirm or refute it?"*
- Identify likely **key drivers** — the branches most likely to explain the majority of the problem. These will receive priority in the next step.

### 3. Prioritize Issues
Use an impact × feasibility matrix to focus on the key drivers. Apply the 80/20 rule ruthlessly.
- Rate each issue branch on: impact if solved (high/medium/low) and ease of resolution (high/medium/low).
- Which 20% of issues drive 80% of the observed problem? These are your key drivers.
- Identify "quick wins" (high impact, high feasibility) — act on these immediately.
- State which issues are deferred and why. A deferred issue is not ignored; it is consciously set aside until the key drivers are resolved.
- If analysis resources are constrained, cut low-impact branches before cutting key drivers.

### 4. Design the Analysis
Determine what analyses must be done to prove or disprove each prioritized hypothesis. Design before you gather.
- For each prioritized issue: what specific evidence would confirm the hypothesis? What would refute it?
- What is the cheapest, fastest way to get that evidence? (Log query? Code search? Reproduce locally? Talk to a team member?)
- Design analyses that produce a clear **yes/no/inconclusive** result. Avoid open-ended exploration without a falsifiable question.
- Assign owners and timeboxes. Prefer hours over days for individual analyses.
- Identify dependencies between analyses — if Analysis B depends on the outcome of Analysis A, sequence accordingly.
- Before gathering data, ask: *"If this analysis comes back inconclusive, what is my fallback?"*

### 5. Gather the Data
Collect only the evidence needed to test the hypotheses. Resist the temptation to gather "interesting" data that does not directly address a prioritized question.
- Execute the analyses designed in Step 4.
- For each piece of evidence, record its source, reliability, and any limitations.
- If the planned data is unavailable, do not stall. Ask: *"What is the best available proxy?"* and note the gap.
- Categorize each piece of evidence as data-backed, intuition-backed, or assumption.
- Stop gathering when additional data no longer changes the recommended action — the remaining uncertainty is immaterial.

### 6. Interpret the Results
Evaluate the evidence against each hypothesis and develop a course of action.
- For each hypothesis, render a verdict: **confirmed**, **refuted**, or **inconclusive**.
- When a hypothesis is refuted, state what was learned — a disproven hypothesis is progress, not failure.
- When inconclusive, state what missing data would resolve the uncertainty and whether obtaining it is worth the cost.
- Look for patterns across hypotheses. Do multiple branches point to the same root cause?
- Apply the **"so what?"** test: for each finding, ask *"What does this mean for the decision we need to make?"* If the answer is "nothing," the finding is interesting but not actionable — deprioritize it.
- Revisit your initial hypothesis from Step 1. Has it been confirmed, refined, or replaced?

### 7. Synthesize and Communicate
Structure findings top-down using the Pyramid Principle, then frame them for your audience using SCQA. Synthesis and communication are a single step — you have not finished solving the problem until the solution is understood and accepted.

#### 7a. Pyramid Synthesis
- Lead with the **headline recommendation** — the one-sentence answer.
- Support with 2–4 **key arguments**, each backed by evidence from the analyses.
- Use the "governing thought" pattern: *"We should [action] because [reason 1], [reason 2], and [reason 3]."*
- Call out residual uncertainty and its materiality to the recommendation.
- Distinguish between findings that are data-backed, intuition-backed, or assumed.

#### 7b. SCQA Communication
Structure the narrative using Situation, Complication, Question, Answer.
- **Situation**: the stable context everyone agrees on. Start here to establish common ground.
- **Complication**: what changed, what is at stake, or why the status quo is unsustainable.
- **Question**: the explicit question the analysis answers. This should map directly to your Step 1 problem statement.
- **Answer**: the recommendation, with supporting evidence, tradeoffs, and implementation considerations.

#### 7c. Generate Buy-In
- Tailor the communication to the audience. What do they care about? What objections will they raise?
- Pre-empt the hardest objection by addressing it in your narrative before the audience asks.
- If the recommendation requires a decision from others, make the ask explicit: *"I need [decision] from [person/group] by [date] to proceed."*

## Output Format (Strict)
Produce sections in this exact order:

1. Problem Statement
   - One-sentence "How to…" framing with scope boundaries.
   - Initial hypothesis: *"My best guess at the answer is…"*
   - Business need driving the problem.

2. Issue Tree (MECE)
   - Top-level branches with sub-questions. Identify likely key drivers.
   - State how each branch tests the initial hypothesis.

3. Prioritization Matrix
   - Impact × feasibility rating for each branch. Key drivers highlighted.
   - Which issues are deferred and why.

4. Analysis Design
   - For each prioritized issue: hypothesis to test, evidence that would confirm/refute, method, owner, timebox.
   - Dependencies between analyses.

5. Evidence Gathered
   - Per hypothesis: evidence collected, source, reliability, and classification (data-backed / intuition-backed / assumption).
   - Data gaps and proxies used.

6. Interpretation
   - Per hypothesis: confirmed, refuted, or inconclusive. Key evidence.
   - "So what?" for each finding. Patterns across hypotheses.
   - Revisited initial hypothesis: confirmed, refined, or replaced?

7. Pyramid Synthesis
   - Headline recommendation. 2–4 supporting arguments with evidence classification.

8. SCQA Communication
   - Situation, Complication, Question, Answer in explicit paragraphs.
   - Audience-specific buy-in considerations and explicit decision ask.

9. Recommended Next Step
   - The smallest safe next action and which agent should take it.

## Safety Notes
- Do not treat hypotheses as conclusions before evidence is gathered — label intuition-backed claims explicitly.
- Do not let the framework become analysis paralysis — use the one-day answer to force early direction and timebox each step.
- If data is unavailable, use the best proxy and classify it honestly; never fabricate certainty.
- Balance intuition and data — a timely decision with known uncertainty is better than a perfect decision too late.
- Keep the output concise; this is a structuring tool, not a replacement for discovery or planning.

## Worked Example: Intermittent Latency Spikes in Checkout Service

This walkthrough applies the full method to a realistic software problem to show what each step produces in practice.

### Step 1: Frame the Problem

- **Problem statement**: "How to eliminate intermittent P99 latency spikes (200ms → 2s) in the checkout service given we have no recent deploys and the issue started 72 hours ago?"
- **Initial hypothesis (one-day answer)**: "My best guess is a downstream dependency is timing out under peak load, because the spikes correlate with traffic bursts and the checkout service itself shows healthy CPU/memory."
- **Business need**: Financial — every 100ms of latency costs ~0.5% conversion. Current impact: ~$12K/day in lost revenue.
- **Scope**: Checkout service and its direct dependencies (payment gateway, inventory service, fraud detection). Out of scope: upstream cart service, CDN, frontend rendering.

### Step 2: Structure the Problem (MECE)

1. **Downstream dependency degradation** *(key driver)* — Is a downstream service (payment, inventory, fraud) responding slower?
2. **Infrastructure/resource contention** *(key driver)* — Is the checkout service starved for CPU, memory, connections, or I/O?
3. **Data or state accumulation** — Is something growing over time (cache, queue, connection pool, log files)?
4. **Recent environmental change** — Did something change 72 hours ago that we missed?

### Step 3: Prioritize Issues

| Branch | Impact | Feasibility | Verdict |
|---|---|---|---|
| 1. Downstream dependency | High | High (traces exist) | **Key driver** |
| 2. Resource contention | High | High (metrics exist) | **Key driver** |
| 3. Data accumulation | Medium | Medium (heap dump) | Deferred — only if 1+2 inconclusive |
| 4. Environmental change | Low | High (audit logs) | Quick 30-min check only |

### Step 4: Design the Analysis

| Issue | Hypothesis | Confirms if... | Method | Owner | Timebox | Fallback |
|---|---|---|---|---|---|---|
| 1. Downstream latency | Payment gateway timing out | P99 gateway latency correlates with checkout spikes | Jaeger traces | Alice | 2h | tcpdump sample at peak |
| 2. Pool exhaustion | Connection pool hits max during spikes | Active connections = max during spike windows | Datadog + netstat | Bob | 1.5h | Enable pool metrics, observe next spike |
| 4. Env change | Silent infra change | Audit log shows change in 72h window | CloudTrail + config diff | Alice | 0.5h | None — low cost |

### Step 5: Gather the Data

| Evidence | Source | Classification | Notes |
|---|---|---|---|
| Payment gateway P99 flat at 45ms during spikes | Jaeger | **Data-backed** | Refutes hypothesis 1 |
| Connection pool hits max (200) during 3 of 4 spikes | Datadog | **Data-backed** | Pool exhaustion confirmed |
| Fraud detection P99 up from 50ms → 800ms during spikes | Jaeger | **Data-backed** | New finding — fraud is the bottleneck, not payment |
| No infra changes in 72h | CloudTrail | **Data-backed** | Branch 4 eliminated |
| Pool config: max=200, timeout=1000ms | Config | **Data-backed** | Explains why 800ms calls exhaust pool at ~250 req/s |

### Step 6: Interpret the Results

| Hypothesis | Verdict | "So what?" |
|---|---|---|
| 1. Payment gateway timing out | **Refuted** | Eliminated. Gateway is healthy. |
| 2. Connection pool exhaustion | **Confirmed** | Pool max (200) too low. Root cause found. |
| 4. Environmental change | **Refuted** | Eliminated. |

**Revisited initial hypothesis**: Directionally correct (downstream), wrong dependency (fraud not payment). Pool exhaustion was an amplifying factor missed in the initial guess.

### Step 7: Synthesize and Communicate

**Pyramid Synthesis**:
- **Headline**: Increase fraud detection connection pool to 500 with 200ms timeout + circuit breaker, because fraud P99 at 800ms exhausts the pool under peak, causing checkout P99 spikes to 2s.
- **Argument 1** *(data-backed)*: Fraud P99 = 800ms during spikes (Jaeger).
- **Argument 2** *(data-backed)*: Pool max=200 saturates at ~250 req/s (Datadog).
- **Argument 3** *(intuition-backed)*: Fraud slowdown may be transient. Circuit breaker protects checkout regardless.

**SCQA**:
- **Situation**: Checkout at ~300 req/s peak, depends on payment, inventory, fraud. Stable for 6 months.
- **Complication**: 72h ago P99 spiked 200ms→2s. ~$12K/day revenue loss. No deploys.
- **Question**: How to eliminate latency spikes given no recent code or config changes?
- **Answer**: Increase fraud pool to 500 + circuit breaker. Config change (low risk, reversible, minutes to deploy).
- **Buy-in**: Pre-empt "treating symptom not cause" — fraud root-cause runs in parallel, checkout recovery doesn't wait.
- **Decision ask**: Platform lead approval to deploy pool config change by EOD.

**Recommended next step**: Deploy to staging, load-test at 500 req/s, promote. Hand off to `senior-software-engineer`.
