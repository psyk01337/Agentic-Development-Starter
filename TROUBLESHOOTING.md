# Troubleshooting Guide

Common issues and solutions when using the Agentic Development Starter.

## Validation Errors

### "Missing check script" error

**Problem**: Validation fails with "Missing check script: .github/scripts/..."

**Solution**: Ensure all files from `.github/scripts/` are present in your repository. The starter requires all validation scripts to function.

```bash
# Check which scripts are missing
ls -la .github/scripts/

# Re-copy from starter if needed
cp -r Agentic-Development-Starter/.github/scripts/ .github/
```

### "actions/checkout@v4" resolver warning

**Problem**: VS Code shows "Unable to resolve action `actions/checkout@v4`"

**Solution**: This is a VS Code local resolver limitation, not an actual error. The workflows will run correctly on GitHub Actions. You can safely ignore this warning.

### Line ending warnings (CRLF/LF)

**Problem**: Git shows "LF will be replaced by CRLF" warnings

**Solution**: The starter includes a `.gitattributes` file that enforces LF line endings. If you still see warnings:

```bash
# Renormalize all files
git add --renormalize .
git commit -m "Normalize line endings"
```

## Workflow Issues

### GitHub Actions not running

**Problem**: Workflows don't trigger on push or pull request

**Solution**:
1. Ensure workflows are in `.github/workflows/` directory
2. Check that the workflow file has valid YAML syntax
3. Verify the `on:` triggers are configured correctly
4. Check repository settings → Actions → General → Allow all actions

### Workflow fails with permission errors

**Problem**: "Permission denied" when running validation scripts

**Solution**: Ensure scripts have execute permissions:

```bash
chmod +x .github/scripts/*.sh
chmod +x .github/hooks/scripts/*.sh
chmod +x evals/*.sh
```

## Agent/Skill/Prompt Issues

### Agent not recognized

**Problem**: Custom agent doesn't appear in VS Code

**Solution**:
1. Ensure the file is in `.github/agents/` directory
2. File must end with `.agent.md`
3. File must contain required sections: Handoff Memory, Escalation, Required Inputs, Constraints, Approach, Output Format
4. Run validation: `bash .github/scripts/check-agent-contracts.sh`

### Skill not working

**Problem**: Skill doesn't execute or shows errors

**Solution**:
1. Ensure skill is in `.github/skills/<skill-name>/SKILL.md`
2. Skill directory must be lowercase with hyphens
3. File must have YAML frontmatter with `name` and `description`
4. Run validation: `bash .github/scripts/check-starter-skills.sh`

### Prompt not available

**Problem**: Prompt doesn't appear in slash commands

**Solution**:
1. Ensure prompt is in `.github/prompts/` directory
2. File must end with `.prompt.md`
3. File must contain required sections: Context, Deliverables, Safety Boundaries, Output Format
4. Run validation: `bash .github/scripts/check-prompt-contracts.sh`

## Hook Policy Issues

### Hook policy tests fail

**Problem**: Hook policy tests fail with unexpected results

**Solution**:
1. Check `.github/hooks/policy-rules.tsv` for syntax errors
2. Ensure TSV file uses tabs (not spaces) as delimiters
3. Verify regex patterns are valid PCRE syntax
4. Run tests: `bash .github/scripts/check-hook-policy.sh`

### Pre-tool policy not blocking

**Problem**: Dangerous commands are not being blocked

**Solution**:
1. Ensure hook scripts are in `.github/hooks/scripts/`
2. Check that policy rules are loaded correctly
3. Verify the hook is configured in your agent runtime
4. Test manually: `echo "rm -rf /" | bash .github/hooks/scripts/pre-tool-policy.sh`

## MCP Issues

### MCP server not connecting

**Problem**: MCP server fails to start or connect

**Solution**:
1. Ensure MCP server is enabled in `.vscode/mcp.json`
2. Check server configuration and permissions
3. Review `docs/runbooks/mcp-servers.md` for approval checklist
4. Check MCP server logs for errors

### MCP security warnings

**Problem**: Validation reports MCP security issues

**Solution**:
1. Review `.vscode/mcp.json` for enabled servers
2. Ensure all high-risk servers have been reviewed
3. Update server configurations to follow security best practices
4. Run validation: `bash .github/scripts/check-mcp-posture.sh`

## Memory Issues

### Memory not persisting

**Problem**: Agent memory doesn't persist across sessions

**Solution**:
1. Ensure memory instructions are in `.github/instructions/memory.instructions.md`
2. Check that memory provider is configured (if using Honcho)
3. Verify memory scope is set correctly (session vs durable)
4. Review `docs/runbooks/memory-strategy.md`

### Memory contains sensitive data

**Problem**: Memory validation reports sensitive data

**Solution**:
1. Review memory contents for secrets, tokens, or credentials
2. Remove any customer private data or production logs
3. Ensure memory follows the three-layer model
4. Run validation: `bash .github/scripts/check-starter-workflow.sh`

## Performance Issues

### Validation is slow

**Problem**: Validation takes too long to complete

**Solution**:
1. Use parallel validation: `bash .github/scripts/check-starter-workflow.sh` (now includes timing)
2. Run individual checks instead of full suite
3. Use VS Code tasks for quick validation
4. Consider incremental validation for large repositories

### CI workflows are slow

**Problem**: GitHub Actions take too long

**Solution**:
1. Use the consolidated `validation.yml` workflow (reduces overhead)
2. Enable workflow concurrency to cancel redundant runs
3. Use caching for dependencies
4. Consider splitting large validation into separate jobs

## Getting Help

If you're still experiencing issues:

1. Check the [runbooks](docs/runbooks/) for detailed guidance
2. Review the [README](README.md) for setup instructions
3. Search existing GitHub issues
4. Open a new issue with:
   - Error messages
   - Steps to reproduce
   - Your environment (OS, Git version, etc.)
   - Relevant configuration files
