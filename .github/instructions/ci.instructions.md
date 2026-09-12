---
applyTo: ".github/workflows/**"
---
# CI/CD Instruction Overlay (GitHub Actions)

These rules are an optional overlay for repositories that edit GitHub Actions workflows. They extend the security baseline with workflow-specific supply-chain, permissions, and secret hygiene rules and are additive to `.github/instructions/security.instructions.md`.

## Action Pinning and Dependency Trust
- Pin third-party actions to a full commit SHA, not a mutable tag or branch; prefer official `actions/*` and `github/*` actions.
- Before adding an action, verify publisher identity, maintenance status, and recent releases; treat workflow dependencies with the same scrutiny as code dependencies.
- Consult the official GitHub Actions security hardening documentation before enabling risky triggers or third-party actions: https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions

## Secrets and Permissions
- Pass secrets only through GitHub Secrets and environment variables; never echo or log them in steps.
- Set an explicit `permissions:` block with the minimum scopes the workflow needs instead of relying on repository-wide defaults.
- Avoid `pull_request_target` flows that check out or execute untrusted pull request code without a documented security review.
- Never write real credentials into workflow files, step output, logs, or changelogs.

## Workflow Hygiene
- Keep jobs small and independent; prefer a matrix over duplicated jobs.
- Treat workflow changes like code: small focused diffs, review, changelog entries, and validation after edits.
- Run `.github/scripts/check-starter-workflow.sh` (or the `.ps1` variant) after changing workflow assets.
