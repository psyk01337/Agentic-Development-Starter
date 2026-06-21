.PHONY: help validate validate-bash validate-ps markdown hooks skills agents prompts mcp evals clean install-hooks

help: ## Show this help message
	@echo "Agentic Development Starter - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

validate: ## Run all validation checks (Bash)
	@echo "Running all validation checks..."
	@bash .github/scripts/check-starter-workflow.sh

validate-bash: ## Run all validation checks (Bash only)
	@bash .github/scripts/check-starter-workflow.sh

validate-ps: ## Run all validation checks (PowerShell only)
	@pwsh .github/scripts/check-starter-workflow.ps1

markdown: ## Check Markdown quality
	@bash .github/scripts/check-markdown-quality.sh

hooks: ## Test hook policy
	@bash .github/scripts/check-hook-policy.sh

skills: ## Validate skill contracts
	@bash .github/scripts/check-starter-skills.sh

agents: ## Validate agent contracts
	@bash .github/scripts/check-agent-contracts.sh

prompts: ## Validate prompt contracts
	@bash .github/scripts/check-prompt-contracts.sh

mcp: ## Check MCP posture
	@bash .github/scripts/check-mcp-posture.sh

evals: ## Run evaluation harness
	@bash evals/run-evals.sh

clean: ## Clean temporary files and caches
	@echo "Cleaning temporary files..."
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".DS_Store" -delete
	@echo "Clean complete"

install-hooks: ## Install pre-commit hooks
	@echo "Installing pre-commit hooks..."
	@command -v pre-commit >/dev/null 2>&1 || { echo "Error: pre-commit is not installed. Install with: pip install pre-commit"; exit 1; }
	@pre-commit install
	@echo "Pre-commit hooks installed successfully"

check-all: validate markdown hooks skills agents prompts mcp ## Run all individual checks
	@echo "All checks passed!"

quick-validate: ## Run quick validation (manifest, skills, agents only)
	@bash .github/scripts/check-starter-manifest.sh
	@bash .github/scripts/check-starter-skills.sh
	@bash .github/scripts/check-agent-contracts.sh
	@echo "Quick validation complete"
