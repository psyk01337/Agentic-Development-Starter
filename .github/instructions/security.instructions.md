---
applyTo: "**/*"
---
# Security Instructions

The always-applied security baseline. Stack overlays may add constraints but must not weaken these defaults.

## Baseline (OWASP-aligned)
- Validate, normalize, and constrain untrusted input at boundaries.
- Guard against injection (SQL, shell, template, command, path, header) and prevent SSRF or unchecked fetches.
- Block unsafe file access, insecure deserialization, and dynamic code execution.

## Access Control
- Enforce authorization on protected actions and resources; authentication alone is not authorization. Keep the check close to the resource and the state change.
- Apply least privilege to users, services, tokens, and runtime roles; deny by default when policy context is missing.
- No privileged behavior behind hidden flags, debug routes, or undocumented endpoints.

## Data Protection and Cryptography
- Use approved primitives and libraries; never invent custom crypto.
- Encrypt sensitive data in transit and at rest where the architecture requires it.
- Never store plaintext secrets, credentials, or private keys in source-controlled files; use rotation-capable patterns for signing material.

## Supply Chain
- Pin or lock dependency versions (no `*`, `^`, or `~latest` in production manifests), commit lockfiles, and verify integrity with checksums or hash pins (`--require-hashes`, npm `integrity`). Audit transitive dependencies and keep the graph shallow.
- Before adding a dependency, check maintenance status, publish-date anomalies, download count, advisories, and exact package identity: typosquatting and name confusion are common. Prefer widely-adopted libraries with an active disclosure process.
- Version-pin scanners, SAST tools, linters, and base images; a compromised scanner poisons every downstream review.
- Reject plain-HTTP registries and any override that bypasses certificate validation (`--trusted-host`, `--index-url http://`, `npm --registry http://`). Never disable TLS outside a documented local-only setup; treat any bypass as requiring a security review note.
- Inspect `postinstall` and lifecycle hooks before accepting a dependency; they run at install time with full developer permissions.
- Keep registry credentials in environment variables, never in config files or CI scripts.
- Restrict auto-merge to patch updates and require human review for minor and major bumps, especially execution-layer packages.
- Prefer the latest stable LTS runtime and critical framework versions, check advisories and deprecations before adding or upgrading, and follow each dependency's documented hardening guidance.

## Secrets and Logging
- Never commit secrets, API keys, tokens, or private certificates, and never write real credentials into `.env` files.
- Redact sensitive values in logs, errors, traces, and test fixtures; never log request bodies, auth headers, tokens, session IDs, or raw PII.

## File, Network, and Execution
- Validate file paths against allowed roots, restrict outbound calls to expected destinations and protocols, and keep command execution explicit and parameterized. Never pass untrusted input to a shell; prefer static dispatch over dynamic import.
- Avoid `curl | bash`, recursively forced deletes, destructive wildcards, and `git reset --hard`.

## Verification
- Add or update tests for authz, input validation, and error paths, and include a security review note in the PR for auth, secrets, network, file, or command changes.
- State residual risk and compensating controls when remediation is deferred.