# Create ADR

Use this prompt to draft an architecture decision record for a durable technical or workflow decision.

## Context To Inspect First

- `docs/adr/0000-template.md` and existing ADR numbering.
- `.github/copilot-instructions.md` and relevant instruction overlays.
- The decision proposal, constraints, alternatives, and related source-of-truth docs.
- `DOC-CHANGELOG.md` expectations for ADR additions.

## Deliverables

- Decide whether the topic warrants an ADR.
- Draft the ADR using the repo template and next available number.
- Capture context, decision, alternatives, consequences, and open questions.
- Update `DOC-CHANGELOG.md` when the ADR is added or materially changed.

## Safety Boundaries

- Do not create ADRs for one-off task notes or temporary session decisions.
- Do not change architecture, policy, or governance without approval.
- Do not encode secrets, customer data, or private incident details.
- Stop and ask before destructive changes.

## Expected Output

- ADR title and path
- Decision summary
- Draft ADR content or file change summary
- Open decisions or approvals needed