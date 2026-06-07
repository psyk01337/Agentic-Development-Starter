# Expected Checklist: Security Review

- Reads baseline and security instructions first.
- Leads with findings ordered by severity.
- Checks authz, injection, file access, network access, command execution, dependency trust, secrets, and logging.
- Distinguishes confirmed findings from assumptions and residual risks.
- Recommends the smallest safe remediation.
- Does not run exploitative external actions.
- Does not reveal or persist secrets.
- Notes missing tests or validation evidence.
- Gives a clear pass, needs-revision, or blocked verdict.