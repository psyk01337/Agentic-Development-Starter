# Ingest Project Docs

Use this prompt when a PRD, design brief, architecture note, API contract, or other planning document must become repo truth before implementation starts.

## Context To Inspect First

- The attached or referenced source document or documents. Check `docs/inputs/` if present when the user places source documents there. If a document is unavailable or unreadable, say so and stop; do not reconstruct it from memory.
- `.github/copilot-instructions.md`, `.github/agent-catalog.md`, `docs/runbooks/adopting-existing-github.md`, and `docs/runbooks/starter-composition.md`.
- The current `README.md`, `CHANGELOG.md`, `DOC-CHANGELOG.md`, `docs/` tree, `.github/starter-modules.json`, and any existing PRD, architecture, design, or API docs.
- The actual application code and tests when the document describes an existing system.

## Deliverables

- Record provenance: source name, version or date, document type, and confidentiality level in the generated doc header and in `docs/inputs.md`; create that tracked index from the starter template if it is missing.
- Extract and classify:
  - goals, non-goals, personas, and user journeys
  - functional requirements with stable IDs and acceptance criteria
  - non-functional requirements for performance, security, privacy, compliance, accessibility, and reliability
  - data model, integrations, API contracts, and external dependencies
  - constraints, assumptions, and unresolved questions
- Write or update repo-truth docs:
  - `docs/prd.md` for product requirements
  - `docs/architecture.md` for system design, boundaries, and data flow, or the confirmed project path when the starter's `docs/ARCHITECTURE.md` must remain
  - `docs/api.md` when an API contract is present
  - `docs/design-brief.md` when UX or UI intent is present
  - `docs/adr/` for durable decisions the source document makes
- Keep exact source wording where precision matters; summarize elsewhere. Do not invent missing requirements.
- Build a requirements traceability table: requirement ID, source section, planned feature or slice, and acceptance criteria.
- Map the documented stack and scope to `.github/starter-modules.json` and the matching instruction overlays. Enable only overlays the document justifies and whose files exist in the repository.
- Produce a gap analysis: what the repository already satisfies, what is missing, and what needs a decision.
- Update the project context in `README.md`, then update `CHANGELOG.md` only for executable or configuration changes and `DOC-CHANGELOG.md` for documentation changes.
- Recommend the first `build-feature` slice and list the inputs it needs.

## Safety Boundaries

- Confirm the target is a downstream project repository, not the starter template. Do not overwrite the starter's `README.md` or `docs/ARCHITECTURE.md`; stop and ask for the downstream project path if the target is ambiguous.
- If `docs/ARCHITECTURE.md` contains starter-specific content, do not replace it without explicit approval; use the project architecture path the user confirms.
- Do not implement application code in this prompt; the output is repo truth and a plan.
- Do not invent requirements, APIs, data fields, compliance claims, performance targets, or user research that are not in the source.
- Do not silently resolve contradictions. List them and stop for a decision when they affect architecture, security, scope, cost, or irreversible behavior.
- Do not overwrite an existing PRD, architecture, design, or API document without showing the proposed change and preserving the prior version in the changelog or an ADR.
- Do not add dependencies, enable MCP servers or durable memory, or change security policy from a planning document without explicit approval.
- Stop and ask before destructive changes, broad rewrites, or removal of existing repo truth.
- Keep secrets, customer data, and confidential document content out of logs and generated examples; record only the minimum needed and mark the artifact.

## Expected Output

- Source inventory and provenance
- Extracted requirements, constraints, assumptions, and open questions
- Files created or updated
- Requirements traceability table
- Stack and overlay mapping with module changes
- Gap analysis, risks, and decisions needed
- Recommended first feature slice and the inputs for `build-feature`

## Promotion Note

Keep this as a prompt until it has been used on at least three real projects or the same extraction and validation steps repeat. Promote it to a skill only when the workflow is stable; a skill adds manifest, validator, and maintenance surface.
