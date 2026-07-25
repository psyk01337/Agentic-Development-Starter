# Quick Start Guide

Get up and running with the Agentic Development Starter in 5 minutes.

## Prerequisites

- Git
- Bash (Linux/macOS) or PowerShell (Windows)
- A GitHub repository

## Installation

### 1. Copy the starter files

```bash
# Clone this repository
git clone https://github.com/psyk01337/Agentic-Development-Starter.git

# Copy the .github directory to your project
cp -r Agentic-Development-Starter/.github /path/to/your/project/
```

**Alternative for brand-new projects:** Clone the starter directly and rename it as your project root — then add your app code in an `app/` directory alongside the workflow assets. After your first commit, use the `initialize-new-project` prompt to adapt all documentation to your project's name, tech stack, and goals. See `docs/runbooks/starter-adoption.md` §0 for the full clone-as-template path.

### 2. Review the configuration

Open `.github/copilot-instructions.md` and review the baseline instructions. These apply to all repositories using this starter.

### 3. Choose your adoption mode

Read `docs/runbooks/starter-adoption.md` to understand the different adoption modes:

- **Minimal Install**: Core instructions and validation only
- **Team Mode**: Add agents, skills, and prompts
- **Advanced Mode**: Add approval-gated handoffs and eval harness
- **Enterprise Mode**: Add org-level governance

### 4. Run validation

```bash
# Bash
bash .github/scripts/check-starter-workflow.sh

# PowerShell
.github/scripts/check-starter-workflow.ps1
```

### 5. Commit and push

```bash
git add .github/
git commit -m "Add agentic development starter"
git push
```

## Next Steps

- Review the available [prompts](.github/prompts/) for common tasks
- Explore the [skills](.github/skills/) for workflow playbooks
- Check out the [agents](.github/agents/) for specialist roles
- Read the [runbooks](docs/runbooks/) for operational guidance

## Common Tasks

### Plan a small feature
Use the `plan-small-feature` prompt or the `tech-planner` agent.

### Implement a small change
Use the `implement-small-diff` prompt or the `senior-software-engineer` agent.

### Review code
Use the `review-current-diff` prompt or the `code-reviewer` agent.

### Create an ADR
Use the `create-adr` prompt or the `architecture-reviewer` agent.

## Need Help?

- Check the [troubleshooting guide](TROUBLESHOOTING.md)
- Review the [runbooks](docs/runbooks/)
- Open an issue on GitHub
