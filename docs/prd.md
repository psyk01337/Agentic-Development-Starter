# <Project>: Product Requirements

Repo truth for this repository. An intake document lands in `docs/inputs/` first, then its
content is routed here once; edit this file when requirements change, and re-ingest a new
intake version instead of amending history.

| Field | Value |
| --- | --- |
| Source | `docs/inputs/<intake>.md` |
| Source version | <date> draft <n> |
| Owner | <who decides product scope> |
| Confidentiality | Internal |
| Ingested | <date> |

## Problem

What is broken or missing today, for whom, and what it costs them. One paragraph. If this
cannot be stated without naming the solution, the problem is not yet understood.

## Target user

Who this is for and the conditions they use it under. Constraints that matter to design
belong here, not in a later section that gets skipped.

## Goals

1. <Outcome, stated so it can be verified>
2. <Outcome>
3. <Outcome>

## Functional requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | <Behaviour the product must have> | Must |
| FR-2 | <Behaviour> | Should |

## Non-functional requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | <Measurable constraint: latency, payload, accessibility, determinism> |
| NFR-2 | <Security or privacy constraint> |

## Decisions

Open questions that will shape more than one slice. Each closes with a date and an owner,
and the answer belongs in an ADR when it is load-bearing.

| # | Question | What it constrains | Owner | Status |
| --- | --- | --- | --- | --- |
| 1 | <Question> | <What cannot be built until it is answered> | <Who decides> | Open |

## Traceability

Requirements map to slices in this order. Each slice is one `build-feature` run, opened
with a declared write set and closed with recorded evidence.

| Slice | Covers | Depends on | Status |
| --- | --- | --- | --- |
| S1 <Name> | FR-1 | - | Not started |
| S2 <Name> | FR-2 | S1 | Not started |

A requirement is delivered when its slice is recorded `done` and archived under
`docs/runs/`. Naming a file is not delivery.

## Verification

<Command that proves the application works. A slice is done when this passes and the
result is recorded, not when the code exists.>

## Out of scope

- <Explicitly excluded from this version, with the reason>