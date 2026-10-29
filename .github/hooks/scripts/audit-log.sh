#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LOG_DIR="${HOOK_LOG_DIR:-${REPO_ROOT}/.github/hooks/logs}"
LOG_PATH="${LOG_DIR}/agent-audit.log"

mkdir -p "${LOG_DIR}"

PAYLOAD=""
if [[ ! -t 0 ]]; then
  PAYLOAD="$(cat)"
fi

json_field() {
  # A missing field must not fail the hook: these scripts run under set -e.
  printf '%s' "${PAYLOAD}" | grep -oP "\"$1\"\s*:\s*\"\K[^\"]*" | head -n 1 || true
}

TOOL_NAME="${1:-$(json_field toolName)}"
ACTION="${2:-$(printf '%s' "${PAYLOAD}" | sed -n 's/.*"toolArgs"[[:space:]]*:[[:space:]]*//p' | sed 's/}$//')}"
RESULT="${3:-}"
SESSION_ID="${4:-$(json_field sessionId)}"

TOOL_NAME="${TOOL_NAME:-unknown}"
SESSION_ID="${SESSION_ID:-unknown}"
RESULT="${RESULT:-unknown}"

# Audit records must never carry credentials: redact secret-shaped values, clamp
# the preview, and escape it so each record stays one parseable JSON line.
ACTION="$(printf '%s' "${ACTION}" \
  | tr -d '\r\n' \
  | sed -E 's/(sk-[A-Za-z0-9]{8,}|ghp_[A-Za-z0-9]{8,}|github_pat_[A-Za-z0-9_]{8,}|akia[0-9a-z]{16}|(token|secret|password|api[_-]?key|client_secret)[[:space:]]*[=:][[:space:]]*"[^"]*")/[REDACTED]/g' \
  | cut -c1-160 \
  | sed 's/\\/\\\\/g; s/"/\\"/g')"
ACTION="${ACTION:-unknown}"

NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

printf '{"timestamp":"%s","event":"postToolUse","sessionId":"%s","tool":"%s","action":"%s","result":"%s"}\n' "$NOW" "$SESSION_ID" "$TOOL_NAME" "$ACTION" "$RESULT" >> "$LOG_PATH"
