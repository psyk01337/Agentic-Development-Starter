#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LOG_DIR="${REPO_ROOT}/.github/hooks/logs"
LOG_PATH="${LOG_DIR}/agent-audit.log"

mkdir -p "${LOG_DIR}"

TOOL_NAME="${1:-unknown}"
ACTION="${2:-unknown}"
RESULT="${3:-unknown}"
SESSION_ID="${4:-unknown}"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

printf '{"timestamp":"%s","event":"postToolUse","sessionId":"%s","tool":"%s","action":"%s","result":"%s"}\n' "$NOW" "$SESSION_ID" "$TOOL_NAME" "$ACTION" "$RESULT" >> "$LOG_PATH"
