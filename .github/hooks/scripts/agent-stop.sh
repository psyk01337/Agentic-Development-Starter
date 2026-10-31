#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
ENGINE="${REPO_ROOT}/.github/scripts/agentic_engine.py"

# Overridable so the stub can be exercised without arming a live session.
STATE_DIR="${AGENTIC_STATE_DIR:-${REPO_ROOT}/.agentic/state}"
LOG_DIR="${REPO_ROOT}/.github/hooks/logs"

PAYLOAD=""
if [[ ! -t 0 ]]; then
  PAYLOAD="$(cat)"
fi

# Being on PATH is not the same as working: Windows ships a python3.exe App
# Execution Alias that is a stub which fails at runtime.
find_usable_python() {
  local candidate
  for candidate in python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 \
      && "${candidate}" --version 2>&1 | grep -qE '^Python [0-9]+\.'; then
      command -v "${candidate}"
      return 0
    fi
  done
  return 1
}

trace() {
  local decision="$1"
  local armed="$2"
  mkdir -p "${LOG_DIR}" 2>/dev/null || return 0
  local active="false"
  if printf '%s' "${PAYLOAD}" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    active="true"
  fi
  printf '{"at":"%s","event":"agentStop","armed":%s,"stopHookActive":%s,"decision":"%s"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${armed}" "${active}" "${decision}" \
    >> "${LOG_DIR}/agent-stop.log" 2>/dev/null || true
}

# The event must be recorded even when no run is armed, otherwise "the hook
# never fired" and "the hook fired and was ignored" are indistinguishable.
if [[ ! -d "${STATE_DIR}" || ! -f "${ENGINE}" ]]; then
  trace "skipped" "false"
  exit 0
fi

PYTHON_BIN="$(find_usable_python || true)"
if [[ -z "${PYTHON_BIN}" ]]; then
  echo "[WARN] agent stop check skipped: no working Python interpreter" >&2
  trace "skipped-no-python" "true"
  exit 0
fi

OUTPUT=""
STATUS=0
OUTPUT="$(printf '%s' "${PAYLOAD}" | "${PYTHON_BIN}" "${ENGINE}" check-stop --state-dir "${STATE_DIR}" 2>/dev/null)" || STATUS=$?

if [[ "${STATUS}" -ne 0 ]]; then
  echo "[WARN] agent stop check failed; allowing the stop" >&2
  trace "error" "true"
  exit 0
fi

if printf '%s' "${OUTPUT}" | grep -q '"decision"[[:space:]]*:[[:space:]]*"block"'; then
  printf '%s\n' "${OUTPUT}"
  trace "block" "true"
else
  trace "allow" "true"
fi

exit 0