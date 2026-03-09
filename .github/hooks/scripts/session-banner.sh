#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LOG_DIR="${REPO_ROOT}/.github/hooks/logs"
LOG_PATH="${LOG_DIR}/session.log"

mkdir -p "${LOG_DIR}"
SESSION_ID="${1:-$(date +%s)}"
USER_NAME="${USER:-unknown}"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

printf '{"timestamp":"%s","event":"sessionStart","sessionId":"%s","user":"%s"}\n' "$NOW" "$SESSION_ID" "$USER_NAME" >> "$LOG_PATH"

echo "=== Agentic Session Guardrails Enabled ==="
echo "Session: ${SESSION_ID}"
echo "Policy : .github/hooks/agent-policy.json"
echo "Rules  : .github/hooks/policy-rules.tsv"
echo "Audit  : .github/hooks/logs/agent-audit.log"
echo "No secrets, no destructive commands, no unsafe remote execution."
