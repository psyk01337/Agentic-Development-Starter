---
name: security-check
description: Run a focused application security review against code and configuration changes.
---
# Skill: security-check

## When to Use
Use this skill for any change touching auth, input handling, file/network access, secrets, or dependency upgrades.

## Trigger Examples
- "Run a security check on this endpoint change."
- "Audit this diff for injection and authz issues."
- "Security review these config updates."

## Checklist
- Authorization: protected operations verify permissions, tenant boundaries, and resource ownership.
- Injection vectors: SQL, shell, template, path traversal, and unsafe eval patterns checked.
- Secrets and logging: no token leakage, no sensitive payload logs, no hardcoded credentials.
- File and network access: SSRF controls, safe path normalization, allowlist/denylist use.
- Dependency risks: vulnerable/outdated packages and risky transitive changes considered.

## Output Format (Strict)
If issues exist, return:
1. Findings
- Markdown table with columns: `Severity | Issue | File/Line | Fix`
2. Priority Actions
- Numbered list of the top fixes by risk reduction.

If clean, return exactly:
- `No issues found.`
