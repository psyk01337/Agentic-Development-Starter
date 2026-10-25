# Source Document Inputs

Place PRDs, design briefs, architecture notes, API contracts, and other planning documents in `docs/inputs/` before running `route-project-inputs.prompt.md`. Create the directory when you first use it. Run the router in the downstream project repository, not in the starter template.

This file is the tracked provenance index, routing log, and format guide. The `docs/inputs/` directory is an intake area, not repo truth. The router uses `ingest-project-docs` to turn each source into `docs/prd.md`, `docs/architecture.md`, `docs/api.md`, and `docs/design-brief.md` as applicable.

## Workflow Destinations

| Workflow | Use when | Output |
| --- | --- | --- |
| `initialize-new-project` | The repository is a fresh clone with generic starter context and needs a project name, stack, goals, or overlay setup. | README, changelogs, enabled overlays |
| `ingest-project-docs` | A PRD, design brief, architecture note, API contract, requirements, or research document should become repo truth. | `docs/prd.md`, `docs/architecture.md`, `docs/api.md`, `docs/design-brief.md` |
| `build-feature` | A bounded feature specification has acceptance criteria and can be delivered as one vertical slice. | Code, tests, review, QA, changelogs |
| `improve-repo` | A document describes starter or workflow friction, validation gaps, or agent, skill, and prompt improvements. | One bounded repository improvement |
| `defer` | The source is incomplete, unreadable, or ambiguous. | Missing-input list |

One `route-project-inputs` invocation processes every file in `docs/inputs/`. A PRD is never passed directly to `build-feature`; ingest it first. Run at most one `build-feature` slice per invocation and queue the rest. Ambiguous files are deferred, not guessed.

## Routing Log

`route-project-inputs.prompt.md` writes the routing decision here before executing it.

| Source file | Type | Confidence | Target workflow | Order | Reason | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `example-prd.md` | PRD | High | `ingest-project-docs` | 1 | Product requirements must become repo truth before coding | Pending |
| `example-feature.md` | Feature spec | High | `build-feature` | 2 | Bounded acceptance criteria for one vertical slice | Pending |

## Supported Formats

Preferred:

- Markdown (`.md`)
- Plain text (`.txt`)
- Pasted text in the chat

Acceptable after conversion:

- HTML converted to Markdown
- PDF converted to Markdown or text
- DOCX converted to Markdown or text
- Spreadsheets exported to CSV or Markdown tables
- Images only after OCR or a written transcription

Not directly supported:

- Binary Office or PDF files without conversion
- Scanned images without OCR
- Proprietary formats the agent cannot read
- Password-protected or encrypted files

If a source cannot be read, stop and ask for a converted copy. Do not reconstruct the document from memory.

## Provenance Template

Record each source before or during ingestion:

| Source file | Type | Version or date | Owner | Confidentiality | Repo-truth output |
| --- | --- | --- | --- | --- | --- |
| `example-prd.md` | PRD | 2026-10-01 | Product | Internal | `docs/prd.md` |
| `example-design.md` | Design brief | 2026-10-03 | Design | Internal | `docs/design-brief.md` |

Add one row per source. Repeat the same provenance in the generated doc header so a reader does not have to find this table.

## Handling Rules

- Keep source copies immutable; do not edit the original while extracting.
- Prefer a link or reference over committing a confidential document.
- Never place secrets, credentials, customer data, or production logs in this directory.
- Mark confidential sources and keep them out of logs, examples, and public artifacts.
- Remove or archive stale sources only after the generated repo truth and changelog record are reviewed.
- If two sources conflict, record both and list the conflict as an open decision; do not silently choose one.
