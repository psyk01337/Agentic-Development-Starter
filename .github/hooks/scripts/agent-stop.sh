#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
ENGINE="${REPO_ROOT}/.github/scripts/agentic_engine.py"

# Overridable so the stub can be exercised without arming a live session.
STATE_DIR="${AGENTIC_STATE_DIR:-${REPO_ROOT}/.agentic/state}"

PAYLOAD=""
if [[ ! -t 0 ]]; then
  PAYLOAD="$(cat)"
fi

# No tracked run means no loop to keep alive. Without this guard the hook would
# run on every turn end in every repository that uses the starter.
if [[ ! -d "${STATE_DIR}" || ! -f "${ENGINE}" ]]; then
  exit 0
fi

PYTHON_BIN="$(command -v python3 || command -v python || true)"
if [[ -z "${PYTHON_BIN}" ]]; then
  echo "[WARN] agent stop check skipped: no Python interpreter on PATH" >&2
  exit 0
fi

# A failure here must never trap the turn. A non-zero exit or unparseable output
# would either deny work or loop the agent, so the fallback is always "allow".
if ! OUTPUT="$(printf '%s' "${PAYLOAD}" | "${PYTHON_BIN}" "${ENGINE}" check-stop --state-dir "${STATE_DIR}")"; then
  echo "[WARN] agent stop check failed; allowing the stop" >&2
  exit 0
fi

if printf '%s' "${OUTPUT}" | grep -q '"decision"[[:space:]]*:[[:space:]]*"block"'; then
  printf '%s\n' "${OUTPUT}"
fi

exit 0