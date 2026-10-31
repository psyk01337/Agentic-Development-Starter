#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LOG_DIR="${REPO_ROOT}/.github/hooks/logs"
LOG_PATH="${LOG_DIR}/session.log"

mkdir -p "${LOG_DIR}"

PAYLOAD=""
if [[ ! -t 0 ]]; then
  PAYLOAD="$(cat)"
fi

json_field() {
  # A missing field must not fail the hook: these scripts run under set -e.
  printf '%s' "${PAYLOAD}" | grep -oP "\"$1\"\s*:\s*\"\K[^\"]*" | head -n 1 || true
}

SESSION_ID="${1:-$(json_field sessionId)}"
SESSION_ID="${SESSION_ID:-$(date +%s)}"
USER_NAME="${USER:-unknown}"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

printf '{"timestamp":"%s","event":"sessionStart","sessionId":"%s","user":"%s"}\n' "$NOW" "$SESSION_ID" "$USER_NAME" >> "$LOG_PATH"

# stdout is parsed as hook output, so the banner goes to stderr. Printing human
# text on stdout makes the harness treat the whole payload as unparseable.
cat >&2 <<BANNER
=== Agentic Session Guardrails Enabled ===
Session: ${SESSION_ID}
Policy : .github/hooks/agent-policy.json
Rules  : .github/hooks/policy-rules.tsv
Audit  : .github/hooks/logs/agent-audit.log
No secrets, no destructive commands, no unsafe remote execution.
BANNER

# Inject the engine's stage context so the agent starts knowing where it is
# instead of discovering it on the first refused turn end. Only a top-level
# `additionalContext` is consumed for sessionStart; a wrapped field is ignored.
STATE_DIR="${AGENTIC_STATE_DIR:-${REPO_ROOT}/.agentic/state}"
ENGINE="${REPO_ROOT}/.github/scripts/agentic_engine.py"
if [[ -d "${STATE_DIR}" && -f "${ENGINE}" ]]; then
  PYTHON_BIN="$(command -v python3 || command -v python || true)"
  if [[ -n "${PYTHON_BIN}" ]] \
    && "${PYTHON_BIN}" --version 2>&1 | grep -qE '^Python [0-9]+\.'; then
    CONTEXT="$("${PYTHON_BIN}" "${ENGINE}" active-context --state-dir "${STATE_DIR}" 2>/dev/null || true)"
    if [[ "${CONTEXT:0:1}" == "{" ]]; then
      printf '%s\n' "${CONTEXT}"
    fi
  fi
fi

exit 0
