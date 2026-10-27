---
name: decision-trail
description: Maintains an auditable decision trail for complex or autonomous tasks, recording timestamp, phase, decision, reason, evidence, and result with evidence as pointers rather than pasted content.
---
# Skill: decision-trail

## When to Use
Use this skill for complex or autonomous tasks: each meaningful decision — including reversals, skipped stages, and deferred work — is recorded so the task can be audited afterward without replaying the whole session.

## Suggested Fields
Record each decision with these suggested fields:

- timestamp
- phase
- decision
- reason
- evidence
- result

## Evidence
Evidence should point to things such as:

- test output
- commit
- file and line
- screenshot
- trace
- browser artifact
- benchmark
- command output

Prefer pointers over long prose. Do NOT confuse decision history with workflow state. For trivial changes, do not create unnecessary logging artifacts.

## Procedure
1. Identify the complex or autonomous task and its current phase.
2. Record each meaningful decision as one entry using the suggested fields.
3. Point evidence at the artifact location rather than pasting the artifact content.
4. Skip the trail entirely for trivial changes.

## Boundary
A decision trail is an audit record, not workflow state and not a completion declaration. It does not satisfy the verification evidence requirements on its own; only the orchestrator declares completion after verification evidence meets the success predicate.

## Division of Labor
- Changelogs record landed changes as durable repo truth; the trail records task-time decisions and points at changelog entries instead of duplicating them.
- ADRs record durable one-time decisions with tradeoffs; a decision that must persist belongs in an ADR, with the trail pointing at it.
- The session-compaction skill produces compact continuation briefs for resumption; the trail is an input to compaction, not a replacement.
- Transient execution state belongs to the workflow-state mechanism; persistent information belongs in the decision trail, not transient execution state.

## Safety Notes
- Never record secrets, credentials, tokens, or raw logs in the trail; point at artifacts without pasting sensitive content.
- Do not treat the trail as repo truth by itself; durable decisions must point to repo truth files.

## Verification Checklist
- Each entry explains the decision with evidence pointers; the suggested fields are guidance, not mandatory fields.
- Trivial changes produced no trail artifacts.
- The trail is not mistaken for workflow state or completion evidence.
- No secrets appear in the trail.

## Referenced Scripts Or Resources
- `update-09142026.md` Phase 11
- `.github/roles/orchestration-policy.json`
- `docs/runbooks/memory-strategy.md`
