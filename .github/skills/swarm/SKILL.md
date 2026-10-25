---
name: swarm
description: Optional overlay skill for the supervisor orchestration overlay that runs multiple agents on different independent slices concurrently, detects shared mutable state before parallel execution, and aggregates results only after all required slices finish.
---
# Skill: swarm

## When to Use
Use when the repo has enabled `overlay-supervisor-orchestration` and one task decomposes into different independent slices that can run concurrently. Do not confuse this with `arena-bakeoff`:

- ARENA: multiple agents solve the SAME problem competitively.
- SWARM: multiple agents solve DIFFERENT independent slices concurrently.

Example swarm: one agent takes the backend slice, one takes the tests, one does the documentation research, and one does the migration audit.

## Preconditions (Strict)
- Detect shared mutable state before parallel execution. Slice the work so that no two agents write the same files or state; when shared state cannot be avoided, run the overlapping slices serially instead.
- Parallel agents must not silently overwrite each other's work. Name each slice's write set before starting, and treat any overlap between write sets as a stop condition.

## Execution
1. Decompose the task into independent slices and name each slice's write set.
2. Delegate each slice to an allow-listed agent.
3. Run the independent slices concurrently.
4. Aggregate results only after all required slices finish; a missing slice result is a missing input, not a partial success.

## Output Format (Strict)
1. Slice list with write sets and the shared-state check result
2. Delegations issued
3. Aggregated result after all slices finished
4. Any overlap or serialization decisions
5. Verification evidence per the repo's standards
