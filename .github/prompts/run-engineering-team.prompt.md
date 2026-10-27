# Run Engineering Team

Use this prompt when one request should run through the full SDLC team: discovery, design, implementation, review, QA, security, documentation, release, and retrospective.

## Context To Inspect First

- `.github/copilot-instructions.md`, `.github/agent-catalog.md`, `docs/runbooks/engineering-team.md`, `docs/runbooks/agentic-engine.md`, and `.github/skills/supervisor-orchestration/SKILL.md`.
- `.github/roles/orchestration-policy.json` for task classes, playbooks, approval categories, the specialist allow-list, and delegation depth.
- `.github/roles/tool-access.json` for each agent's capability boundary.
- The project's PRD, architecture, API docs, current code, tests, and validation commands.
- `CHANGELOG.md` and `DOC-CHANGELOG.md`.

## Deliverables

- Confirm the supervisor overlay is enabled. If it is not, produce a guided delegation plan or use the core guided chain; do not pretend delegation occurred.
- Classify the request with `taskClasses` and `complexityRouting`.
- Build a team plan and task board with task ID, owner, reviewer, scope, acceptance criteria, write set, dependencies, evidence, status, and approval category.
- Assign only approved specialists and keep exactly one delegation level.
- Run the SDLC stages in order; use `swarm` for independent slices, `arena-bakeoff` for competing designs, `adversarial-review` for review, and `verification-evidence-loop` for completion.
- Drive write work through `.github/scripts/agentic_engine.py` instead of an unbounded manual repair loop: `init`, `next`, `record`, `approve`, `status`.
- Stop at approval categories; serialize unbounded or overlapping writes.
- Let the engine stop the loop on `VERIFIED`, an identical failure signature, an exhausted attempt budget, or `INCONCLUSIVE`. Escalate the blocker packet instead of retrying manually.
- Reconcile results into one coherent outcome; consolidate blocking findings into one repair pass when the engine schedules `repair`.
- Update both changelogs and record a decision trail.
- Report team status, evidence, residual risk, and the next action.

## Safety Boundaries

- Do not create a second delegation level or let a specialist delegate.
- Do not push, merge, deploy, or publish.
- Do not add dependencies, change schemas, enable MCP servers or durable memory, or change security policy without explicit approval.
- Do not mark work complete without verification evidence; `INCONCLUSIVE` is never success.
- Stop and ask before destructive changes, scope expansion, conflicting acceptance criteria, or architecture and security decisions.
- Keep secrets, customer data, and production data out of logs, examples, and artifacts.
- If the runtime cannot delegate, produce a guided plan and say so.

## Expected Output

- Task classification and routing criterion
- Team plan and task board
- Assignments with declared write sets
- Execution status and blockers
- Review, QA, and verification evidence
- Consolidated result and residual risk
- Changelog and decision-trail locations
- Recommended next action and approval needed
