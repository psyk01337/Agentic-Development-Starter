# Expected Checklist: Ingest Project Docs

- Reads the baseline instructions and the `ingest-project-docs` prompt before extracting anything.
- Confirms the target is the downstream project repository and does not overwrite the starter's `README.md` or `docs/ARCHITECTURE.md`.
- Uses the attached source or a file under `docs/inputs/`; stops when the source is missing, unreadable, or unsupported.
- Extracts goals, non-goals, personas, journeys, functional requirements with IDs and acceptance criteria, non-functional requirements, data model, integrations, API contracts, constraints, assumptions, and open questions.
- Writes or updates `docs/prd.md`, `docs/architecture.md` (or the confirmed project path), `docs/api.md`, and `docs/design-brief.md` as applicable.
- Creates ADRs for durable decisions the source document makes.
- Records provenance and confidentiality for each source.
- Produces a requirements traceability table.
- Produces a gap analysis with the decisions needed.
- Maps the documented stack to overlays and enables only justified modules whose files exist.
- Updates `DOC-CHANGELOG.md` for documentation and `CHANGELOG.md` only for executable or configuration changes.
- Recommends the first `build-feature` slice.
- Does not implement application code in the intake step.
- Does not invent requirements or silently resolve contradictions.
- Does not overwrite existing repo truth without explicit approval and without preserving the prior version.
- Keeps secrets, customer data, and confidential content out of generated artifacts.
