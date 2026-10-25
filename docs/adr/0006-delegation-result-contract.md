# ADR 0006: Delegation Result Contract — Structured Specialist Returns

- Status: Accepted
- Date: 2026-09-26
- Approved: 2026-09-26 by the repository maintainer (user), after the architecture review passed with conditions; the review's documentation condition C1 (full-validator commands) is applied in the same change
- Owners: Team
- Related: `docs/adr/0005-routing-policy-as-data.md`, `.github/schema/delegation-plan.schema.json`, `.github/roles/orchestration-policy.json`, `.github/scripts/check-supervisor-orchestration.sh`, `.github/scripts/check-supervisor-orchestration.ps1`, `docs/runbooks/supervisor-orchestration.md`

## Context

The vNext direction Phase 4 requires every specialist agent to return a bounded handoff contract so the orchestrator can reconcile results without re-reading each agent's full conversation. The supervisor already has a request-side contract: `delegation-plan.schema.json` records what is delegated. There is no result-side contract: today a worker returns prose, and the supervisor extracts files changed, verification performed, evidence, and open questions by reading it.

Phase 5 of the same direction ties the return contract to verification evidence: results must use the VERIFIED / NOT_VERIFIED / INCONCLUSIVE vocabulary from `evidenceRequirements` in `orchestration-policy.json`, and INCONCLUSIVE must never count as success. ADR 0005 fixed that vocabulary in data; this ADR reuses it in the result schema so the vocabulary has one data source.

The contract is a communication contract, not proof. Verification agents and the orchestrator must inspect the underlying artifacts; a structured result that claims VERIFIED does not become verified by being well-formed.

## Decision

Add a result-side contract as data:

- `delegation-result.schema.json` under `.github/schema/`: a JSON Schema (draft 2020-12, the subset the repo-local validators evaluate) with required fields `resultVersion`, `agent`, `task`, `status`, `summary`, `filesChanged`, `assumptions`, `risks`, `verificationPerformed`, `evidence`, `openQuestions`, `recommendedNextAction`. `status` records the delegated work's own outcome (`completed`, `partial`, `blocked`, `failed`); it does not mark the task complete, which only the orchestrator may do. `verificationPerformed` entries carry `surface`, `method`, `result`, and `evidenceReference`; `result` is enum-constrained to the policy's vocabulary and `surface` to the policy's closed surface set.
- A worked example `simple-bugfix-delegation-result.json` under `.github/examples/supervisor-orchestration/`, validated against the schema by both validator twins — the same pattern the delegation-plan example uses.

Both twins gain deterministic checks and one negative fixture per platform:

- The example must validate against the schema.
- The schema's `agent` enum must match the canonical `specialistAllowList`, its `result` enum the policy's `resultVocabulary`, and its `surface` enum the policy's surface keys — drift goes red the same way the delegation-plan agent-enum drift already does.
- A negative fixture removes `verificationPerformed` from the example and requires rejection with the missing-required-property diagnostic.

## Consequences

Positive outcomes

- Workers return bounded structured results; the supervisor reconciles from fields rather than from prose.
- The completion invariant gains a static shape: a result without a verification record is not expressible as a valid contract.
- The verification vocabulary has one data source: the policy file, with the schema checked against it.

Trade-offs and risks

- The contract is data with a fixture cost: changing a field name or the vocabulary becomes a governance change with fixture updates.
- The schema cannot make a result true. Well-formed INCONCLUSIVE or NOT_VERIFIED results remain possible, and the prompt-level completion rule is what refuses to treat them as success.

Operational impacts

- Both validator twins change together with the new fixture, and the new files are listed in the overlay's manifest entry.
- The supervisor agent file and runbook point at the contract; no core file changes, so no `core-governance-change` gate.

## Rollout Plan

1. Record and approve. Done: the architecture review passed with conditions on 2026-09-26, condition C1 was applied in the same change, and the maintainer accepted the ADR on 2026-09-26.
2. Data first: add the schema and the worked example; register both in the overlay manifest entry.
3. Validators: validate the example, pin the three enum drifts, and add the `malformed-delegation-result` negative fixture per platform.
4. Docs: reference the contract in the supervisor agent file and runbook; update both changelogs.

## Validation

- Both twins reject a result example that omits `verificationPerformed`, as a negative fixture with a unique message substring.
- The shipped example passes both twins.
- Both umbrella entry points pass all ten checks on both platforms.

## Follow-up

- Revisit if real deployments show the required-field set too heavy for read-only investigations.
- Phase 5 landed on 2026-09-26: `.github/skills/verification-evidence-loop/SKILL.md` emits this contract's `verificationPerformed` entries directly, and both validator twins pin the skill's reference to this schema.