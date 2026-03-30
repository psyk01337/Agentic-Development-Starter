---
applyTo: "**/*"
---
# Security Instructions

## Baseline Checks (OWASP-aligned)
- Validate, normalize, and constrain all untrusted input at boundaries.
- Enforce authorization on protected actions and resources; do not rely on authentication alone.
- Guard against injection vectors (SQL, shell, template, command, path, and header manipulation).
- Prevent SSRF and unsafe file path access (no unchecked external or internal fetches).
- Avoid insecure deserialization and unsafe dynamic code execution.

## Access Control and Session Safety
- Apply least privilege for users, services, tokens, and runtime roles.
- Keep authorization checks close to protected resources and state-changing operations.
- Deny by default when policy context is missing.
- Do not expose privileged behavior through hidden flags, debug routes, or undocumented endpoints.

## Data Protection and Cryptography
- Use approved cryptographic primitives and libraries; do not invent custom crypto.
- Encrypt sensitive data in transit and at rest when repository architecture requires it.
- Never store plaintext secrets, credentials, or private keys in source-controlled files.
- Use key rotation-capable patterns for secrets and signing material.

## Secure Configuration and Supply Chain
- Keep security-sensitive defaults explicit and conservative.
- Pin or lock dependency versions using the repository's package management conventions; avoid open-ended ranges (`*`, `^`, `~latest`) in production manifests.
- Use lockfiles (`package-lock.json`, `yarn.lock`, `uv.lock`, pinned `requirements.txt`, `Pipfile.lock`) and commit them — never gitignore lockfiles for deployed artifacts.
- Verify package integrity using checksums or hash pins where the package manager supports it (e.g. `--require-hashes` for pip, `integrity` fields in npm lockfiles).
- Review third-party package additions for maintenance status, publish-date anomalies, download count, and known vulnerabilities before merging.
- Be vigilant for typosquatting and package-name confusion attacks — verify exact package names and publisher identity before adding new dependencies.
- Treat security tooling (scanners, SAST tools, linters, base images) as first-class supply chain targets — they must be version-pinned; compromising a scanner silently poisons all downstream reviews (ref: TeamPCP/Trivy/Checkmarx/KICS attack pattern, 2025–2026).
- Do not install packages from plain HTTP registries or sources without TLS; `--trusted-host`, `--index-url http://`, and `npm --registry http://` overrides that bypass certificate validation are blocked.
- Inspect postinstall scripts and lifecycle hooks in new dependencies before accepting them; a malicious `postinstall` runs at install time with full developer permissions.
- Prefer well-maintained, widely-adopted libraries with active security disclosure processes over niche or unmaintained alternatives.
- Audit transitive dependencies periodically; restrict the dependency graph depth where practical.
- Do not disable TLS/certificate verification except in explicitly documented local-only setups; treat any TLS bypass as a red flag requiring a security review note.
- Use environment variables and documented setup for registry credentials; never hardcode package source credentials in config files or CI scripts.
- When evaluating auto-update tooling (Dependabot, Renovate, etc.), restrict auto-merge to patch-only updates and require human review for minor and major bumps, especially for security-sensitive or execution-layer packages — auto-updating supply chain attacks are an active and growing threat vector.

## Secrets and Logging
- Never commit secrets, API keys, tokens, or private certificates.
- Redact sensitive values in logs, errors, traces, and test fixtures.
- Use environment variables and documented setup for sensitive config.
- Avoid logging full request bodies, auth headers, tokens, session IDs, or raw PII.

## File, Network, and Execution Boundaries
- Validate file paths against allowed roots and block traversal patterns.
- Restrict outbound network calls to expected destinations and protocols.
- Keep command execution explicit, parameterized, and avoid passing untrusted input to shells.
- Prefer static dispatch patterns over dynamic import or reflection when possible.

## Command and Tool Safety
- Do not use dangerous shell patterns such as `curl | bash`, `rm -rf`, destructive wildcard deletes, or `git reset --hard`.
- Do not write auth tokens or real credentials into `.env` files.
- Prefer explicit, reviewable commands and least-privilege defaults.

## Security Verification Expectations
- Add or update tests for authz checks, input validation, and error-path behavior when relevant.
- For changes touching auth, secrets, file/network access, or command execution, include a brief security review note in the PR description.
- Call out residual risks and compensating controls when full remediation is deferred.
