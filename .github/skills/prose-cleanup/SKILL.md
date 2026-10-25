---
name: prose-cleanup
description: Improves the writing quality of agent-produced prose by removing canned filler, restatement, and false certainty while preserving technical detail.
---
# Skill: prose-cleanup

## Purpose

Improve the writing quality of agent-produced prose: agent responses, ADRs, PR descriptions, documentation, handoffs, and code comments where applicable.

## Remove

- Canned AI introductions.
- Redundant summaries.
- Unnecessary headings.
- Fake certainty.
- Verbose restatement.
- Repetitive conclusions.
- Excessive conversational filler.

## Keep

Preserve technical detail.

Names, numbers, constraints, decisions, evidence, and failure modes stay intact; only the wrapper prose shrinks.

## Boundaries

This skill is NOT responsible for workflow-state storage.

This skill is a writing-quality filter, not a context compressor. Context compaction is a separate capability.

## Execution

1. Read the draft and mark the cuts: introductions, summaries, headings, restatement, filler.
2. Rewrite once, applying the Remove list.
3. Verify technical detail is unchanged.
4. Read the result again and cut what remains. This skill is its own first customer.
