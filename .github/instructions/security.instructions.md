---
applyTo: "**/*"
---
# Security Instructions

## Baseline Checks (OWASP-aligned)
- Validate and sanitize all untrusted input.
- Enforce authorization for protected actions and resources.
- Guard against injection vectors (SQL, shell, template, command, path).
- Prevent SSRF and unsafe file path access (no unchecked external/internal fetches).
- Avoid insecure deserialization and unsafe dynamic code execution.

## Secrets and Logging
- Never commit secrets, API keys, tokens, or private certificates.
- Redact sensitive values in logs, errors, traces, and test fixtures.
- Use environment variables and documented setup for sensitive config.

## Command and Tool Safety
- Do not use dangerous shell patterns such as `curl | bash`, `rm -rf`, or destructive wildcard deletes.
- Do not write auth tokens or real credentials into `.env` files.
- Prefer explicit, reviewable commands and least-privilege defaults.

## Review Requirement
- If a change touches auth, secrets, file/network access, or command execution, include a brief security review note in the PR description.
