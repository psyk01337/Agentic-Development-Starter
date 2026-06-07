# Security Review

Use this prompt to run a focused security review of a diff, workflow asset, or configuration change.

## Context To Inspect First

- `.github/instructions/security.instructions.md` and `.github/copilot-instructions.md`.
- Changed files plus nearby auth, input validation, file, network, command, dependency, and logging code.
- Hook policy rules, MCP templates, secrets handling docs, and CI workflows when relevant.
- Any tests or validation evidence tied to security behavior.

## Deliverables

- Identify concrete vulnerabilities or missing controls first.
- Check secrets, authz, injection, SSRF, unsafe file access, command execution, dependency trust, and logging.
- Distinguish confirmed findings from residual risks.
- Recommend the smallest safe remediation.

## Safety Boundaries

- Do not run exploitative actions against external systems.
- Do not reveal or store secrets found during review.
- Do not enable scanners, MCP tools, or external network checks without approval.
- Stop and ask before destructive changes.

## Expected Output

- Findings by severity
- Evidence and affected files
- Recommended fixes
- Residual risk
- Security validation notes