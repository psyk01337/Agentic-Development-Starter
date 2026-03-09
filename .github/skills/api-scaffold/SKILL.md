---
name: api-scaffold
description: Optional overlay skill for scaffolding backend or service slices from a contract spec with handlers, schemas, tests, and docs stubs.
---
# Skill: api-scaffold

## When to Use
Use this skill when given a new service contract or endpoint specification and the current repo already has a clear backend pattern to follow.

## Trigger Examples
- "Scaffold a FastAPI endpoint for order cancellation."
- "Create route, schema, and tests for this API spec."
- "Generate backend stub for this contract."
- "Scaffold a queue consumer or RPC handler from this contract."

## Checklist
- Parse contract details: transport, path or topic, auth, inputs, outputs, and error cases.
- Generate handler stub aligned to repo conventions.
- Generate schema or model definitions for request and response shapes when applicable.
- Add validation and structured error handling stubs.
- Add test stubs for success, validation failure, authz failure, and server error.
- Add minimal docs entry or stub matching the contract style in the repo.

## Output Format (Strict)
Produce sections in this exact order:
1. Files Changed
- Bullet list of file paths.
2. Code Snippets
- Key snippets for route, schema, and tests.
3. Assumptions
- Bullet list of inferred choices.
4. Follow-up Questions
- Only include if spec is incomplete; otherwise write `None`.
