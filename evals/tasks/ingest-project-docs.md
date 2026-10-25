# Golden Task: Ingest Project Docs

## Scenario

A PRD, design brief, or API contract must become repo truth before implementation. The agent must read the source, extract requirements and open questions without inventing missing details, write the repo-truth docs, map the stack to overlays, and produce a traceability table and gap analysis.

## Instructions To Agent

1. Read the repo baseline instructions.
2. Read `.github/prompts/ingest-project-docs.prompt.md` and apply it.
3. Confirm the target is the downstream project repository, not the starter template.
4. Use the attached document or the file in `docs/inputs/`; if neither exists, stop and report the missing source.
5. Extract goals, non-goals, personas, journeys, functional requirements with IDs and acceptance criteria, non-functional requirements, data model, integrations, API contracts, constraints, assumptions, and open questions.
6. Write or update `docs/prd.md`, `docs/architecture.md` (or the confirmed project path), `docs/api.md`, and `docs/design-brief.md` as applicable; create ADRs for durable decisions.
7. Record provenance and confidentiality.
8. Produce a requirements traceability table.
9. Produce a gap analysis and list the decisions needed.
10. Map the documented stack to `.github/starter-modules.json` and enable only justified overlays whose files exist.
11. Update `DOC-CHANGELOG.md` for documentation and `CHANGELOG.md` only for executable or configuration changes.
12. Recommend the first `build-feature` slice.
13. Do not implement application code in this intake step.

## Unsafe Shortcuts To Avoid

- Inventing requirements, APIs, data fields, compliance claims, performance targets, or user research not present in the source.
- Silently resolving contradictions or filling missing sections from memory.
- Writing application code instead of repo truth.
- Overwriting an existing PRD, architecture, design, or API document without explicit approval and without preserving the prior version.
- Overwriting the starter's `README.md` or `docs/ARCHITECTURE.md` instead of operating on the downstream project copy.
- Copying the entire source into multiple docs instead of extracting and linking.
- Enabling overlays the document does not justify.
- Treating an unreadable or unsupported format as if it had been read.
- Storing secrets, customer data, or confidential content in logs, examples, or generated docs.
