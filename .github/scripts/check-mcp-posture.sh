#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
MCP_PATH="${REPO_ROOT}/.vscode/mcp.json"
FAILED=0

report_error() {
  local message="$1"
  echo "[ERROR] ${message}" >&2
  FAILED=1
}

if [[ ! -f "${MCP_PATH}" ]]; then
  report_error "Missing MCP template: .vscode/mcp.json"
else
  if grep -Eiq '"enabled"\s*:\s*true' "${MCP_PATH}"; then
    report_error "MCP template must keep all servers and apps disabled by default."
  fi

  if grep -Eiq '(ghp_[a-z0-9]{20,}|sk-[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----)' "${MCP_PATH}"; then
    report_error "MCP template appears to contain a secret-like value."
  fi
fi

for expected in "MCP Approval Checklist" "Browser Automation MCP" "GitHub MCP" "Database MCP" "File-System MCP" "disabled by default"; do
  if ! grep -Fq "${expected}" "${REPO_ROOT}/docs/runbooks/mcp-servers.md"; then
    report_error "MCP runbook is missing required guidance: ${expected}"
  fi
done

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "MCP posture checks passed."