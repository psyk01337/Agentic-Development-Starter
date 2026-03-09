# Repo Agents

This repository uses repo-native custom agents for recurring roles. The starter is modular: keep the core roles, then add specialized overlays only when the target repo benefits from them.

## Operating Model

- Use one main chat as the orchestrator.
- Invoke a specialized agent when the task clearly matches its role.
- Use guided handoffs, not hidden automation. Each agent should recommend the next agent, explain why, and call out blockers or approvals still needed.
- Prefer the generic handoff chain for delivery work: `analyst` -> `tech-planner` or `architecture-reviewer` -> `senior-software-engineer` -> `code-reviewer` and `qa`.
- Treat `senior-software-engineer` as the primary coder. Use `tdd-vitest` only in repositories that actually use Vitest and want a strict red-green-refactor loop.
- Prefer skills for bounded playbooks such as `adr-authoring`, `bug-triage`, `qa-test-plan`, `pr-review`, `security-check`, `release-notes`, and any stack-specific scaffold skills that match the repo.
- Prefer `pr-review` when you want the review skill's fixed output format on a current diff.
- Prefer `code-reviewer` when you want a dedicated reviewer role inside the session, especially when the review needs to stay findings-first while considering repo conventions and nearby context.

Shared role intent lives in `.github/roles/tool-access.json`. Use that file when deciding whether to add a new agent or when tightening tool boundaries across the starter.

## Guided Handoff Contract

Every agent should end its output with these fields:

- `Handoff-ready summary`: the minimum context the next agent needs
- `Recommended next agent`: the best next specialist for the current state
- `Why that next agent`: the reason this handoff is the lowest-risk next step
- `Inputs for next agent`: files, artifacts, or evidence the next agent should consume
- `Decision status`: `ready`, `needs-clarification`, or `blocked`
- `Blockers or approvals needed`: anything that must be resolved before the next handoff

This is a guided chain, not an automatic chain. The orchestrating user or main chat decides whether to take the recommendation.

If a repo enables the approval-gated orchestration overlay, that overlay extends this contract with approval and transition metadata. Those richer fields are overlay-only, not part of the core baseline.

## Agent Set

### `senior-software-engineer`

- File: `.github/agents/senior-software-engineer.agent.md`
- Use for: primary coding and delivery ownership in repos where no stack-specific implementation overlay is needed.
- Role: `implementation`

### `tdd-vitest`

- File: `.github/agents/tdd-vitest.agent.md`
- Use for: strict red-green-refactor implementation loops in repositories that use Vitest.
- Role: `implementation` overlay

### `analyst`

- File: `.github/agents/analyst.agent.md`
- Use for: structured codebase discovery, root-cause analysis, and narrowing unknowns before implementation.
- Role: `analysis`

### `architecture-reviewer`

- File: `.github/agents/architecture-reviewer.agent.md`
- Use for: architecture-fit review, boundary checks, and contract alignment before a change grows in scope.
- Role: `review`

### `tech-planner`

- File: `.github/agents/tech-planner.agent.md`
- Use for: forward-looking technical planning, design artifacts, ADR shaping, and phased delivery planning before implementation starts.
- Role: `planning`

### `code-reviewer`

- File: `.github/agents/code-reviewer.agent.md`
- Use for: findings-first review of correctness, regressions, maintainability, and missing tests.
- Role: `review`

### `qa`

- File: `.github/agents/qa.agent.md`
- Use for: verifying that critical user flows are sufficiently tested and validated with the smallest relevant verification command.
- Role: `analysis`

### `process-improvement`

- File: `.github/agents/process-improvement.agent.md`
- Use for: improving repo workflow assets such as agent files, instructions, skills, and runbooks after friction or a milestone review.
- Role: `workflow-maintenance`

### `orchestration-coordinator`

- File: `.github/agents/orchestration-coordinator.agent.md`
- Use for: optional approval-gated orchestration in repos that explicitly opt into the orchestration overlay.
- Role: overlay workflow coordinator

## Ownership Map

| Agent | Owns | Produces | Typical next handoff |
| --- | --- | --- | --- |
| `analyst` | Discovery, problem framing, root-cause clarity | Findings, scope, constraints, unknowns | `tech-planner` or `senior-software-engineer` |
| `tech-planner` | Design direction, ADRs, phased plans | Design artifacts, tradeoffs, implementation plan | `architecture-reviewer` |
| `architecture-reviewer` | Fit against boundaries, contracts, and architecture rules | Architecture verdict, corrections, risks | `senior-software-engineer` or back to `tech-planner` |
| `senior-software-engineer` | Primary implementation and delivery | Code changes, validation evidence, implementation risks | `code-reviewer` or `qa` |
| `tdd-vitest` | Specialized TDD implementation overlay | Tests-first implementation summary, Vitest evidence | `code-reviewer` or `qa` |
| `code-reviewer` | Findings-first code review | Severity-ordered review findings | `senior-software-engineer` or `qa` |
| `qa` | Verification strategy, risky flows, evidence, release-readiness | QA evidence, gaps, verdict | `senior-software-engineer` or none |
| `process-improvement` | Workflow asset maintenance | Workflow changes, process fixes, repo-level guardrails | none or user decision |
| `orchestration-coordinator` | Optional approval-gated transitions and transition records | Transition recommendation, approval checkpoint, handoff prompt draft | next specialist or none |

## Recommended Sequencing

1. Use `analyst` when the problem is still unclear.
2. Use `tech-planner` when the next step is to design the target solution, choose an option, or finalize a phased delivery plan.
3. Use `architecture-reviewer` when the proposed plan or change touches boundaries, contracts, or module shape and you need a fit review before implementation.
4. Use `senior-software-engineer` when the next step is implementation against an approved plan.
5. Substitute `tdd-vitest` for `senior-software-engineer` when the repo uses Vitest and the change should follow a strict TDD loop.
6. Use `code-reviewer` when the work needs a findings-first review before it is considered ready.
7. Use `qa` when you need explicit verification of test sufficiency and risky user flows.
8. Use `process-improvement` only for workflow assets, and only with clear user approval before edits.

## Sequencing Shortcuts

### Simple fix

- `senior-software-engineer` -> `code-reviewer`

### Clear feature with known scope

- `senior-software-engineer` -> `code-reviewer` -> `qa`

### Unclear problem or high-risk change

- `analyst` -> `tech-planner` -> `architecture-reviewer` -> `senior-software-engineer` -> `code-reviewer` -> `qa`

### Architecture or platform decision

- `tech-planner` -> `architecture-reviewer` -> `senior-software-engineer`

### Workflow asset change

- `process-improvement`

### Approval-gated overlay flow

- `orchestration-coordinator` -> approved specialist handoff

## Manual Handoff Outputs

- `analyst` handoff: problem statement, scope, constraints, unknowns, and impacted areas.
- `tech-planner` handoff: options considered, recommended target design, phased plan, assumptions, and risks.
- `architecture-reviewer` handoff: architecture-fit decision, boundary or contract concerns, and required plan corrections.
- `senior-software-engineer` handoff: implemented change summary, validation commands run, docs or tests updated, and residual implementation risks.
- `tdd-vitest` handoff: implemented change summary, tests added or updated, commands run, and residual implementation risks.
- `code-reviewer` handoff: findings ordered by severity, regressions or maintainability concerns, and smallest safe fixes.
- `qa` handoff: validation evidence, risky user flows checked, coverage gaps, and pass or fail status.

## Deliberate Exclusions

The adapted agent set intentionally does not include the following concepts from the sample framework:

- Unsupported model pins
- External Flowbaby memory tools
- `agent-output/` lifecycle and status-document systems
- Automatic multi-agent handoff chains
- Automatic planner, UAT, and devops role automation beyond the repo's documented manual handoff workflow

Those exclusions are deliberate. If the repo later needs deeper orchestration, add it as a new optional overlay with explicit approval gates and auditable transitions rather than reintroducing the sample assumptions by copy-paste.

See `docs/runbooks/approval-gated-handoffs.md` for the overlay-only orchestration model.
