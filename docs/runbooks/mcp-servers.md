# MCP Servers Runbook

## What MCP Is

Model Context Protocol (MCP) lets the agent use external tools and data sources through well-defined server interfaces.

## Add a Server (Safe Starter)

1. Open `.vscode/mcp.json`.
2. Start from the placeholder templates rather than assuming a Node or Python runtime exists.
3. Add a server entry under `servers` with `enabled: false` first.
4. Use placeholders and environment variable references only. Do not hardcode tokens.
5. Keep commands constrained to known safe actions.

All shared MCP examples must stay disabled by default. Enabling a server is a local or team decision that requires review.

## Validate a Server

1. Enable one server entry temporarily.
2. Start a fresh chat session and open Agent Debug panel.
3. Confirm server handshake and available tools are shown.
4. Run one harmless tool call (for example, read-only search).
5. Disable again if review is not complete.

## Team vs Local Configuration

- Commit shared defaults in `.vscode/mcp.json`.
- Keep machine-specific secrets/overrides out of source control.
- Document required env vars in this runbook or project README.

## Template Guidance

- Keep `servers` empty until the repo has chosen real MCP servers.
- Use placeholder commands such as `<replace-with-runtime>` and `<replace-with-server-entrypoint>` in examples.
- Do not commit sample paths that imply files or runtimes every repo should have.

## MCP Approval Checklist

Before enabling any MCP server, confirm:

- Purpose is clear and cannot be met safely with repo files or built-in tools.
- Required permissions are least privilege and documented.
- Secrets come from environment variables or local secret stores, never committed files.
- The server starts disabled in shared config.
- Read-only mode has been tested before write actions.
- Risks and safe-use notes are documented in this runbook or the server template.
- The team knows how to disable, audit, and remove the server.

## Browser Automation MCP

- Purpose: inspect local UI flows, capture screenshots, and validate browser behavior.
- Required permissions: open pages, inspect DOM, capture screenshots, and optionally interact with local dev servers.
- Risks: cookies, session state, private UI data, and external site interaction can leak sensitive context.
- Safe default: local dev server only, no production accounts, no credential capture, disabled by default.

## GitHub MCP

- Purpose: read issues, pull requests, repository metadata, and optionally create review artifacts after approval.
- Required permissions: start read-only; add write scopes only for reviewed workflows.
- Risks: tokens can mutate repositories, expose private metadata, or trigger notifications.
- Safe default: least-privilege token through environment variables, disabled by default.

## Database MCP

- Purpose: inspect schemas, fixture data, or local/staging diagnostics.
- Required permissions: read schema and non-sensitive fixtures by default.
- Risks: sensitive records, credentials, destructive writes, and data retention violations.
- Safe default: local or staging read-only connection, no production data, disabled by default.

## File-System MCP

- Purpose: expose constrained workspace file access to runtimes that need MCP instead of native file tools.
- Required permissions: read workspace files; write access only after review.
- Risks: over-broad roots, path traversal, modification of secrets, and accidental source changes.
- Safe default: workspace-root allowlist, read-only mode, disabled by default.

## MCP App Example

Example idea: `test-dashboard` MCP App.

- Purpose: return a compact UI card showing latest test pass rate, flaky tests, and failed suites.
- Inputs: branch name, test scope, time window.
- Actions: rerun selected suite, open failing test file, export summary.
- Security: read-only by default; rerun actions restricted to local dev environment.
