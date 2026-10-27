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

### "Unable to resolve action" warning in a workflow

**Problem**: VS Code reports `Unable to resolve action ...`, for example `Unable to resolve action actions/checkout@v4, repository or version not found`.

**Cause**: The GitHub Actions extension resolves every `uses:` entry by fetching that action's `action.yml` through the GitHub API (`repos.getContent` with the ref). Its language server reports one message for *every* failed fetch: no network access, a blocked or TLS-inspected proxy, an expired GitHub sign-in, an exhausted API rate limit, or a genuinely missing ref. The ref form is not a factor, because `@v4`, `@v3`, a full version tag, and a commit SHA all request the same file, so rewriting the ref does not change this warning.

**Diagnose it from the extension log**: open the Output panel and select `GitHub Actions Language Server`. The log records the real HTTP status behind the generic message: `401` with `Bad credentials` means the stored VS Code GitHub token is expired, revoked, or belongs to a different signed-in account; `403` means the API rate limit is exhausted; and `404` means the ref genuinely does not exist. When more than one GitHub account is signed in, confirm that the extension is using the account that owns the repository.

**Confirm the workflow is correct**: verify the ref resolves from the command line.

```bash
git ls-remote https://github.com/actions/checkout refs/tags/v4
curl -s -o /dev/null -w '%{http_code}\n' https://api.github.com/repos/actions/checkout/contents/action.yml?ref=v4
```

A `200` from the second command means the action resolves and the warning is local to the editor. Hosted GitHub Actions runners resolve actions independently, so CI results stay authoritative either way.

**Clear it in the editor**:

1. Run `GitHub Actions: Sign in to GitHub` from the Command Palette. Unauthenticated GitHub API access allows 60 requests per hour, which the resolver exhausts quickly; signing in raises the limit to 5,000.
2. Check that the window has internet access. The Actions views stay hidden when the extension cannot reach GitHub; behind a proxy, confirm VS Code's `http.proxy` setting and any TLS-inspection certificate.
3. Run `Developer: Reload Window` to discard cached resolution failures.
4. If the warning remains, open the Output panel and read the extension's log, which records the underlying fetch failure rather than the generic message.

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

### Agent ignores the repo rules

**Problem**: The agent follows general good practice but not this repository's rules

**Solution**:
1. Confirm which file your harness actually reads. `.github/copilot-instructions.md` is the Copilot baseline, and the `core`, `security`, and `memory` instruction files load on every request. Full detail: `docs/runbooks/starter-composition.md`.
2. Remember that "always applied" means always injected as context, not enforced. Nothing prevents a model from ignoring an instruction; only hooks and validators enforce.
3. `.github/agent-catalog.md` is not an instruction file. It is the agent roster and handoff contract, read on demand. Rules that must apply every time belong in the instruction files.
4. If you use a non-Copilot harness, confirm it reads `AGENTS.md` at the repository root rather than `CLAUDE.md`.
5. An instruction file whose `applyTo` glob matches nothing never loads. Run `bash .github/scripts/check-starter-manifest.sh` to catch a missing `applyTo`.

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
3. File must contain required sections: Context To Inspect First, Deliverables, Safety Boundaries, Expected Output
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

## Agentic Engine Issues

### Engine reports "requires Python 3.9 or newer"

The engine uses Python 3.9 features. Check the interpreter and run the self-tests:

```bash
python3 --version
python3 .github/scripts/agentic_engine.py selftest
```

On Windows, `python` usually works where `python3` does not. Use whichever interpreter resolves to 3.9 or newer.

### A run is BLOCKED

A blocked run is a deliberate stop, not a crash. Read the blocker packet:

```bash
python .github/scripts/agentic_engine.py report --run-id <run-id>
```

| Reason | Meaning | Action |
| --- | --- | --- |
| `identical-failure` | The same failure signature repeated | Fix the root cause or change the approach, then start a new run |
| `attempt-budget-exhausted` | `maxRepairAttempts` was reached | Escalate the blocker; do not raise the limit just to pass |
| `inconclusive` | Verification could not produce evidence | Add a real check or fix the environment |
| `write-set-violation` | A changed file was outside the declared write set | Re-scope the task or revert the out-of-scope change |
| `wall-clock-budget-exceeded` | `maxWallClockMinutes` was reached | Split the task or escalate |

Start a new run with a new `--run-id`. `--force` will not replace a blocked run.

### Evidence is rejected

Evidence must be one of:

- a file inside the repository, absolute or relative
- `cmd:`, `test:`, `commit:`, `diff:`, `trace:`, `screenshot:`, `benchmark:`, or `artifact:` with content after the colon
- an `http://` or `https://` URL with a host, a valid port, no credentials, and no query string

Use `artifact:` for signed or tokenized links. A directory is not evidence.

### "state is locked by another process"

Another process holds the run lock. Wait for it to finish. If you are certain no process is running that run, remove the stale lock:

```bash
ls .agentic/state/
rm .agentic/state/.<run-id>.lock
```

Do not delete `.agentic/state/<run-id>.json` unless the run is abandoned.

### State file is corrupt or missing fields

The engine validates state on load. If `report` returns `state is missing required field` or `state has an unknown stage`, the file was edited or partially written. Restore it from your editor history or start a new run. `.agentic/state/` is gitignored, so Git cannot recover it.

### `--force` refuses to replace the run

Only a run still at the `implement` stage can be replaced. Use a new `--run-id`; the later stages are preserved on purpose so the audit trail and blocker packet survive.

### Engine self-tests fail

```bash
python .github/scripts/agentic_engine.py selftest
bash .github/scripts/check-agentic-engine.sh
pwsh -NoProfile -File .github/scripts/check-agentic-engine.ps1
```

The check scripts print the failing test name and traceback.

## Document Ingestion Issues

### A source file cannot be read

Unsupported formats include binary Office or PDF files, scanned images without OCR, encrypted files, and proprietary formats. Convert the source to Markdown or plain text, place it in `docs/inputs/`, and re-run `route-project-inputs.prompt.md` or `ingest-project-docs.prompt.md`.

### A document was routed to the wrong workflow

Review the routing table in `docs/inputs.md`. A PRD or design document is ingested before feature work, a bounded feature specification goes to `build-feature`, and a workflow document goes to `improve-repo`. Correct the row and re-run the router.

## Git Push Issues

### "Permission denied (publickey)" or "could not read Username"

The environment has no authorized GitHub credential. From an interactive terminal:

```powershell
ssh-add $HOME\.ssh\id_ed25519
git push origin main
```

If GitHub rejects the key, add `$HOME\.ssh\id_ed25519.pub` under GitHub, Settings, SSH and GPG keys. For HTTPS, run `git remote set-url origin https://github.com/<owner>/<repo>.git` and let Git Credential Manager prompt. A non-interactive agent session cannot answer that prompt.
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
