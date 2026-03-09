# MCP Servers Runbook

## What MCP Is

Model Context Protocol (MCP) lets the agent use external tools and data sources through well-defined server interfaces.

## Add a Server (Safe Starter)

1. Open `.vscode/mcp.json`.
2. Start from the placeholder templates rather than assuming a Node or Python runtime exists.
3. Add a server entry under `servers` with `enabled: false` first.
4. Use placeholders and environment variable references only. Do not hardcode tokens.
5. Keep commands constrained to known safe actions.

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

## MCP App Example

Example idea: `test-dashboard` MCP App.

- Purpose: return a compact UI card showing latest test pass rate, flaky tests, and failed suites.
- Inputs: branch name, test scope, time window.
- Actions: rerun selected suite, open failing test file, export summary.
- Security: read-only by default; rerun actions restricted to local dev environment.
