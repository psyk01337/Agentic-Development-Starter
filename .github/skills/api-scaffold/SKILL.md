---
name: api-scaffold
description: Scaffold backend API slices from an endpoint spec with schemas, route handlers, tests, and docs stubs.
---
# Skill: api-scaffold

## When to Use
Use this skill when given a new endpoint specification or when converting a requirement into backend API scaffolding.

## Trigger Examples
- "Scaffold a FastAPI endpoint for order cancellation."
- "Create route, schema, and tests for this API spec."
- "Generate backend stub for this contract."

## Checklist
- Parse endpoint spec: method, path, auth, request body, query params, response codes.
- Generate route handler stub aligned to repo conventions.
- Generate schema/model definitions for request/response.
- Add validation and structured error handling stubs.
- Add test stubs for success, validation failure, authz failure, and server error.
- Add minimal API docs entry (or doc stub) matching contract.

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
