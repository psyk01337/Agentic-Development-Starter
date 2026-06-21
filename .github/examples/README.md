# Examples Directory

This directory contains real-world usage examples and patterns for the Agentic Development Starter.

## Purpose

The examples demonstrate how to:
- Configure the starter for different project types
- Use agents, skills, and prompts effectively
- Integrate optional overlays
- Apply the starter to common workflows

## Available Examples

### Overlay Examples

#### Approval-Gated Handoffs
Location: `approval-gated-handoffs/`

Demonstrates how to configure and use approval-gated handoffs between agents:
- `approved-tech-planner-to-senior-software-engineer.json` - Approved handoff example
- `pending-architecture-reviewer-to-senior-software-engineer.json` - Pending approval
- `rejected-qa-to-senior-software-engineer.json` - Rejected handoff with feedback
- `stale-analyst-to-tech-planner.json` - Stale handoff example

#### Hermes Runtime
Location: `hermes/`

Shows how to integrate with the Hermes stateful runtime:
- `hermes-profile.example.md` - Example Hermes profile configuration

#### Honcho Memory
Location: `honcho/`

Demonstrates Honcho durable memory integration:
- `honcho.config.example.json` - Example Honcho configuration

#### Memory Examples
Location: `memory/`

Shows memory strategy patterns:
- `hermes-memory-provider.example.md` - Hermes memory provider example
- `honcho-policy.example.md` - Honcho memory policy example

## How to Use These Examples

### 1. Review Before Enabling

All examples are **disabled by default**. Before enabling any overlay:

1. Read the example files to understand the configuration
2. Review the associated runbook:
   - [Approval-Gated Handoffs](../docs/runbooks/approval-gated-handoffs.md)
   - [Hermes Runtime](../docs/runbooks/hermes-runtime.md)
   - [Honcho Memory](../docs/runbooks/honcho-memory.md)
3. Assess the security implications
4. Enable only what you need

### 2. Copy and Customize

```bash
# Example: Enable approval-gated handoffs
cp .github/examples/approval-gated-handoffs/*.json .github/handoffs/

# Edit the configuration for your needs
# Then enable the overlay in .github/starter-modules.json
```

### 3. Validate Configuration

After enabling an overlay, run validation:

```bash
bash .github/scripts/check-starter-workflow.sh
```

## Example Workflows

### Workflow 1: Simple Bug Fix

**Scenario**: Fix a small bug in production code

**Agents Used**:
- `senior-software-engineer` - Implements the fix
- `code-reviewer` - Reviews the changes
- `qa` - Validates the fix

**Prompts Used**:
- `implement-small-diff.prompt.md` - Guide the implementation
- `review-current-diff.prompt.md` - Guide the review

**Skills Used**:
- `bug-triage` - Analyze the bug
- `qa-test-plan` - Create test plan

### Workflow 2: Feature Development

**Scenario**: Develop a new feature from planning to deployment

**Agents Used**:
- `tech-planner` - Plans the feature
- `architecture-reviewer` - Reviews architecture
- `senior-software-engineer` - Implements the feature
- `security-reviewer` - Reviews security
- `qa` - Tests the feature
- `documentation-maintainer` - Updates docs

**Prompts Used**:
- `plan-small-feature.prompt.md` - Plan the feature
- `create-adr.prompt.md` - Document architecture decisions
- `security-review.prompt.md` - Security review
- `generate-test-plan.prompt.md` - Create test plan

**Skills Used**:
- `adr-authoring` - Write ADRs
- `security-check` - Security review
- `qa-test-plan` - Test planning

### Workflow 3: Security Incident Response

**Scenario**: Respond to a security vulnerability

**Agents Used**:
- `security-reviewer` - Analyzes the vulnerability
- `senior-software-engineer` - Implements the fix
- `code-reviewer` - Reviews the fix
- `qa` - Validates the fix

**Prompts Used**:
- `security-review.prompt.md` - Security analysis
- `implement-small-diff.prompt.md` - Implement fix
- `review-current-diff.prompt.md` - Review fix

**Skills Used**:
- `security-check` - Security review
- `bug-triage` - Triage the issue

### Workflow 4: Documentation Update

**Scenario**: Update documentation for a major release

**Agents Used**:
- `documentation-maintainer` - Updates documentation
- `code-reviewer` - Reviews changes

**Prompts Used**:
- `prepare-release-notes.prompt.md` - Write release notes

**Skills Used**:
- `release-notes` - Generate release notes

## Creating Your Own Examples

When creating custom examples:

1. **Follow the Pattern**
   - Use JSON for configuration examples
   - Use Markdown for documentation examples
   - Include clear comments explaining the configuration

2. **Document the Use Case**
   - What problem does this solve?
   - When should this be used?
   - What are the trade-offs?

3. **Include Validation**
   - Show how to validate the configuration
   - Include expected validation output
   - Document any known issues

4. **Keep It Minimal**
   - Show only what's necessary
   - Avoid over-engineering
   - Focus on the key concepts

## Contributing Examples

To contribute new examples:

1. Create a new directory under `examples/`
2. Add your example files
3. Update this README
4. Ensure validation passes
5. Submit a pull request

## Related Documentation

- [Starter Adoption](../docs/runbooks/starter-adoption.md)
- [Starter Composition](../docs/runbooks/starter-composition.md)
- [Skills](../docs/runbooks/skills.md)
- [Hooks](../docs/runbooks/hooks.md)
- [MCP Servers](../docs/runbooks/mcp-servers.md)
