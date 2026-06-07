# Tool Surface Compatibility Matrix

This matrix maps repo-native workflow expectations to common 2026 AI coding tools. Capabilities change quickly, so treat unknowns as review items rather than assumptions.

Legend:

- Direct: supported by the platform directly.
- MCP: supported through Model Context Protocol or a similar external tool bridge.
- Repo: supported by repository conventions such as prompts, instructions, hooks, and runbooks.
- Unknown: not reliably known or requires local validation.
- Unsupported: not expected to work without a separate integration.

## Capability Matrix

| Operation | Copilot VS Code Agent Mode | Copilot Cloud Agent | Copilot CLI | Claude Code | Codex | Cursor | OpenCode | Hermes Agent |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Read files | Direct | Direct | Direct | Direct | Direct | Direct | Direct | Direct |
| Search files | Direct | Direct | Direct | Direct | Direct | Direct | Direct | Direct |
| Edit/apply patch | Direct | Direct | Direct | Direct | Direct | Direct | Direct | Direct |
| Run terminal | Direct with approval and policy | Direct with platform limits | Direct | Direct | Direct | Direct | Direct | Runtime policy |
| Run tests | Direct via terminal | Direct via workflow environment | Direct | Direct | Direct | Direct | Direct | Runtime policy |
| Browser automation | MCP or extension | Unknown | Unsupported | MCP | MCP or external | Direct or MCP | MCP | Runtime tool |
| GitHub issues/PRs | Direct or GitHub extension | Direct | Direct | MCP or CLI | MCP or CLI | Direct or MCP | MCP or CLI | MCP or runtime tool |
| MCP tools | Direct in VS Code | Unknown | Unknown | Direct | MCP bridge | Direct | Direct | Runtime bridge |
| Hooks/policies | Repo convention plus editor/runtime support | Repo convention and CI | Repo convention | Repo convention | Repo convention | Repo convention | Repo convention | Runtime plus repo convention |
| Skills | Direct VS Code customization | Repo convention | Repo convention | Repo convention | Repo convention | Repo convention | Repo convention | Runtime convention |
| Prompt files | Direct VS Code customization | Repo convention | Repo convention | Repo convention | Repo convention | Direct or repo convention | Repo convention | Runtime convention |
| Custom agents | Direct VS Code customization | Repo convention | Unsupported or repo convention | Repo convention | Repo convention | Direct or repo convention | Repo convention | Runtime convention |
| Memory | Session memory plus optional providers | Platform-dependent | Session only or external | Tool-dependent | Tool-dependent | Tool-dependent | Tool-dependent | Runtime memory plus optional providers |
| Handoffs | Repo convention | Repo convention | Repo convention | Repo convention | Repo convention | Repo convention | Repo convention | Runtime plus repo convention |

## Platform Notes

### GitHub Copilot VS Code Agent Mode

- Best fit for this starter's `.github/prompts`, `.github/instructions`, `.github/agents`, and `.github/skills` assets.
- MCP servers must remain disabled until reviewed.
- Hook policy still needs runtime/editor support or CI validation to enforce outside the local agent loop.

### GitHub Copilot Cloud Agent

- Good fit for repo-native instructions, prompts by convention, CI validation, and PR workflows.
- Validate which local hooks and MCP tools are available in the hosted environment before relying on them.
- Keep workflow checks in CI so cloud work is auditable.

### GitHub Copilot CLI

- Good fit for terminal-centric read, search, edit, and test workflows.
- Treat prompts, skills, custom agents, and handoffs as repo conventions unless the CLI adds first-class support.
- Use hook policy scripts and CI checks as deterministic controls.

### Claude Code

- Good fit for repo-native instructions and terminal workflows.
- MCP can provide browser, GitHub, database, or search tooling when explicitly reviewed.
- Keep memory usage aligned to `docs/runbooks/memory-strategy.md`.

### Codex

- Good fit for patch-based coding and validation loops.
- Treat repo skills, prompt files, and custom agents as conventions unless the runtime exposes native support.
- Verify terminal and browser tool availability per environment.

### Cursor

- Good fit for editor-native code changes and prompt workflows.
- Confirm which `.github` customization assets are consumed natively versus used by convention.
- Keep high-risk automation behind explicit approval.

### OpenCode

- Good fit for open terminal-driven agent workflows.
- MCP and repo conventions can bridge skills, prompts, and tools.
- Confirm hook support before relying on pre-tool enforcement.

### Hermes Agent

- Hermes is a runtime; this starter provides the repo-level operating system.
- Hermes should read repo truth before acting and should not self-modify core instructions without approval.
- Runtime memory must follow the memory strategy and optional Honcho policy.

## Safety Caveats

- Treat unsupported or unknown capabilities as disabled until proven.
- Do not enable shell auto-execution, MCP servers, browser automation, database access, GitHub mutation, or durable memory without review.
- Keep hooks, CI checks, and changelogs as the audit path across platforms.
- Prefer repo convention over platform-specific hidden state for durable workflow decisions.