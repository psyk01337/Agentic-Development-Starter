---
applyTo: "**/*"
---
# Core Starter Instructions

These rules are the language-agnostic baseline for repositories that use this starter.

## Scope And Sources Of Truth
- Start from the repo's actual source-of-truth docs and code, not from starter examples.
- If expected docs do not exist, say so explicitly and proceed from the smallest reliable evidence.
- Apply stack-specific overlays only when the current file type and repo conventions justify them.

## Delivery
- Keep diffs small, reviewable, and tightly scoped to the request.
- Fix root causes when feasible; avoid surface-only patches that preserve unclear behavior.
- When behavior changes, update the nearest relevant tests and docs in the same change.
- Prefer extending existing patterns before introducing new abstractions, roles, or workflow layers.

## Collaboration
- State assumptions quickly when context is missing or conflicting.
- Separate confirmed facts from inferences when scanning or reviewing a repo.
- Prefer modular additions over cross-cutting rewrites when evolving starter assets.

## Safety
- Validate untrusted input at boundaries.
- Keep commands explicit, reviewable, and least-privilege by default.
- Never store secrets or live credentials in source-controlled files, examples, or logs.