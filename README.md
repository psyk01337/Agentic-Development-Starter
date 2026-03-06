# Agentic Development Starter (VS Code, Feb 2026 Workflow)

This repository is structured for repeatable, team-shareable agentic development with:

- Repository instructions and scoped rules
- Reusable skills (playbooks)
- Deterministic hooks for safety and auditability
- MCP server/app starter wiring
- Runbooks and ADRs for decisions

If you are using VS Code Agent Mode, this guide walks you through setup and daily usage end to end.

## 1. What You Get

### Core customization

- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`

### Reusable skills

- `.github/skills/pr-review/SKILL.md`
- `.github/skills/security-check/SKILL.md`
- `.github/skills/api-scaffold/SKILL.md`
- `.github/skills/ui-scaffold/SKILL.md`
- `.github/skills/release-notes/SKILL.md`

### Guardrail hooks

- `.github/hooks/agent-policy.json`
- `.github/hooks/scripts/*.ps1` (Windows-first)
- `.github/hooks/scripts/*.sh` (optional WSL/bash)

### MCP and editor wiring

- `.vscode/mcp.json`
- `.vscode/settings.json`

### Team docs

- `docs/adr/0000-template.md`
- `docs/runbooks/agentic-dev.md`
- `docs/runbooks/mcp-servers.md`
- `docs/runbooks/hooks.md`

## 2. Quick Start (10-15 minutes)

1. Open this repo in VS Code.
2. Open Agent Mode and start a new chat.
3. Confirm customizations are loaded in Agent Debug panel.

- Baseline instruction
- Scoped instructions
- Skills
- Hook policy

1. Read these in order.

- `docs/runbooks/agentic-dev.md`
- `docs/runbooks/hooks.md`
- `docs/runbooks/mcp-servers.md`

1. Keep MCP servers disabled by default in `.vscode/mcp.json` until reviewed.
2. Start your first task with a short plan and execute in small diffs.

## 3. Operating Model (Daily)

### Before starting work

1. State task scope and acceptance criteria in chat.
2. Ask agent for a short plan.
3. Identify risk areas early (auth, secrets, data writes, migrations, command execution).

### During implementation

1. Keep diffs small and focused.
2. Use a skill when task matches a known pattern.

- Review: `pr-review`
- Security pass: `security-check`
- Backend scaffolding: `api-scaffold`
- UI scaffolding: `ui-scaffold`
- Release summary: `release-notes`

1. For UI work, run a browser-tool closed loop.

- Implement
- Verify in browser
- Capture screenshot and console output
- Fix
- Re-verify

1. Record notable decisions; mirror important ones into ADRs.

### After milestone completion

1. Use context compaction (`/compact`) to keep decision-critical context.
2. If exploring alternatives, fork session (`/fork`) instead of derailing the main thread.
3. Run review/security checks before merge.

## 4. How Instructions Apply

### Baseline (always on)

- File: `.github/copilot-instructions.md`
- Enforces small diffs, architecture respect, security hygiene, and ask-before-big-refactor behavior.

### Scoped rules

- Frontend: `.github/instructions/frontend.instructions.md` for `**/*.{ts,tsx,js,jsx}`
- Backend: `.github/instructions/backend.instructions.md` for `**/*.{py,pyi,sql}`
- Security: `.github/instructions/security.instructions.md` for `**/*`

When behavior changes:

- Update tests
- Update docs

## 5. Skills: When and How to Invoke

### `pr-review`

Use when you want correctness/risk-focused review before merge.

Prompt example:

```text
Use pr-review on my current diff. Focus on correctness, edge cases, tests, security, performance, and DX. Follow the skill output format exactly.
```

### `security-check`

Use for auth, input handling, file/network access, secrets/logging, dependency updates.

Prompt example:

```text
Run security-check on the current changes and return the Findings table. If clean, return exactly 'No issues found.'
```

### `api-scaffold`

Use when starting a new endpoint from a spec.

Prompt example:

```text
Use api-scaffold for: POST /orders/{id}/cancel with auth required, request reason:string, responses 200/400/403/404. Generate route + schema + test stubs + docs stub.
```

### `ui-scaffold`

Use when building a screen from a product spec.

Prompt example:

```text
Use ui-scaffold for an Account Settings screen with profile edit, password update, and 2FA status card. Include loading/error/empty/success states and test/story stubs.
```

### `release-notes`

Use after merges or before release cut.

Prompt example:

```text
Use release-notes for merged PRs in this sprint. Provide user-facing notes, internal notes, upgrade notes, and verification.
```

## 6. Hooks and Guardrails

Hook policy is in `.github/hooks/agent-policy.json`.

### Hook lifecycle

- `sessionStart`: prints banner and logs session entry
- `preToolUse`: blocks dangerous patterns
- `postToolUse`: appends audit record

### Currently blocked patterns

- `rm -rf`
- `del /s /q`
- `curl | bash` or similar piped script execution
- Remote content piped to `Invoke-Expression` / `iex`
- Writing likely real secrets/tokens into `.env`

If blocked, use the safer alternative shown by the script output.

### Audit logs

- Session log: `.github/hooks/logs/session.log`
- Tool audit log: `.github/hooks/logs/agent-audit.log`

Both are JSONL-style entries for traceability.

## 7. MCP Servers and MCP Apps

Starter config: `.vscode/mcp.json`

### Safety defaults

- Servers are disabled by default (`"enabled": false`).
- No secrets in committed config.
- Use environment variables for sensitive values.

### Add a server safely

1. Add server entry in `.vscode/mcp.json` with placeholders.
2. Keep it disabled until reviewed.
3. Enable temporarily for validation.
4. Validate in Agent Debug panel.
5. Run one harmless read-only tool call first.

See full guide: `docs/runbooks/mcp-servers.md`.

## 8. Multi-Agent Pattern (Recommended)

Use one main orchestrator session and parallel subagents for targeted tasks.

### Typical split

1. Research subagent

- Locate conventions, impacted files, risks.

1. Implementation subagent

- Propose smallest implementation path.

1. Review subagent

- Check correctness/security/regression risk.

Main session merges outputs and executes final edits.

## 9. Session Memory, Compaction, and Forking

### Session memory

- Keep a short plan and decision log.
- Record assumptions and unresolved questions.

### Context compaction

- Use `/compact` after each meaningful milestone.
- Keep contracts, decisions, and open risks.

### Session forking

- Use `/fork` to evaluate alternate approaches without polluting the main thread.

## 10. Debugging Agent Behavior

Use Agent Debug panel when behavior seems off.

Check:

1. Loaded instructions and apply scopes.
2. Skill detection and invocation path.
3. Hook execution and block reasons.
4. MCP server connection and tool registration.

Most common fixes:

- Incorrect `applyTo` pattern
- Contradictory instructions
- Disabled/misconfigured MCP server
- Prompt too vague for intended skill

## 11. ADR Workflow

Use `docs/adr/0000-template.md` for significant decisions.

Create ADRs for:

- Architecture boundary changes
- New data/storage patterns
- Security posture changes
- Major workflow/process changes

Keep ADRs short and decision-focused.

## 12. Security Checklist (Always)

Before merge, ensure:

1. Input validation and sanitization at boundaries.
2. Authorization checks for protected resources.
3. No secret leakage in code/logs/docs/fixtures.
4. No unsafe command patterns.
5. File/network access paths are constrained and reviewed.

## 13. Practical First 3 Tasks

1. Multi-agent exercise

- Implement ADR-0001 for MCP rollout policy using one research subagent and one review subagent.

1. Browser verification exercise

- Build a small UI page and run closed-loop browser verification with screenshot + console checks.

1. Skill creation exercise

- Use `/create-skill` to draft `incident-triage`, then align format with existing `SKILL.md` files.

## 14. Team Conventions for This Repo

- Keep changes minimal and composable.
- Reuse existing naming conventions.
- Do not introduce heavy frameworks unless explicitly needed.
- Do not commit secrets.
- Ask before broad refactors or large file moves.

---

If you want, the next step can be a concrete `Task 0` where we run a full dry-run:

- start session
- verify hooks
- enable one MCP server safely
- run one scaffold task
- run one review task
- produce release-note stub
