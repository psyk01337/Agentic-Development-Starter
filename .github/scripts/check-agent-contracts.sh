#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
FAILED=0

report_error() {
  local message="$1"
  echo "[ERROR] ${message}" >&2
  FAILED=1
}

assert_file_exists() {
  local relative_path="$1"
  if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
    report_error "Missing required file: ${relative_path}"
  fi
}

assert_file_contains() {
  local relative_path="$1"
  local pattern="$2"
  local description="$3"

  if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
    report_error "Cannot verify ${description} because file is missing: ${relative_path}"
    return
  fi

  if ! grep -Eq "${pattern}" "${REPO_ROOT}/${relative_path}"; then
    report_error "Missing expected content for ${description} in ${relative_path}"
  fi
}

agent_files=(
  ".github/agents/analyst.agent.md"
  ".github/agents/tech-planner.agent.md"
  ".github/agents/architecture-reviewer.agent.md"
  ".github/agents/senior-software-engineer.agent.md"
  ".github/agents/code-reviewer.agent.md"
  ".github/agents/qa.agent.md"
  ".github/agents/process-improvement.agent.md"
  ".github/agents/tdd-vitest.agent.md"
  ".github/agents/orchestration-coordinator.agent.md"
)

for relative_path in "${agent_files[@]}"; do
  assert_file_exists "${relative_path}"
  assert_file_contains "${relative_path}" "## Handoff Memory Contract" "handoff memory contract section"
  assert_file_contains "${relative_path}" "## Escalation and Failure Modes" "escalation and failure modes section"
done

assert_file_contains ".github/AGENTS.md" "## Conditional Delegation Triggers" "conditional delegation trigger table"
assert_file_contains "docs/runbooks/agentic-dev.md" "## 1b\) Redirect Mid-Chain When Signals Appear" "mid-chain redirect runbook guidance"
assert_file_contains "docs/runbooks/agentic-dev.md" "### 4b\) Respect Escalation and Failure Mode Signals" "escalation handling runbook guidance"

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Agent contract check passed."
