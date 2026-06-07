---
name: tool-surface-audit
description: Compare agent platforms and repo tool surfaces against the starter's safety, hook, MCP, memory, and handoff expectations.
---
# Skill: tool-surface-audit

## When to Use
Use this skill when enabling a new coding agent, runtime, MCP server, hook mechanism, or memory provider for a repository.

## Inputs Expected
- Target tool or platform name.
- Available capabilities: read, search, edit, terminal, tests, browser automation, GitHub, MCP, hooks, skills, prompts, agents, memory, and handoffs.
- Security and approval constraints.
- Existing repo rules and module manifest.
- Known unsupported or unknown capabilities.

## Procedure
1. Map concrete tool capabilities to the abstract operations in the compatibility matrix.
2. Identify whether each capability is direct, MCP-mediated, convention-based, unsupported, or unknown.
3. Check dangerous operations against hook policy, MCP approval, and memory rules.
4. Recommend the smallest safe enablement path.
5. Record validation and audit requirements.

## Output Format
- Tool or platform assessed
- Capability mapping
- Safety caveats
- Required repo configuration
- Validation plan
- Decision: ready, needs-review, or blocked

## Verification Checklist
- Unsupported or unknown capabilities are not treated as available.
- MCP and memory integrations remain optional and disabled by default.
- The recommendation aligns with `docs/runbooks/tool-surface-matrix.md`.
- High-risk operations have explicit approval gates.

## Safety Notes
- Do not enable external tools, shell automation, MCP servers, or memory backends during an audit.
- Do not store tokens, tool credentials, or raw audit logs in repo files.
- Stop and ask before destructive changes.

## Referenced Scripts Or Resources
- `docs/runbooks/tool-surface-matrix.md`
- `.github/hooks/policy-rules.tsv`
- `docs/runbooks/mcp-servers.md`
- `docs/runbooks/memory-strategy.md`