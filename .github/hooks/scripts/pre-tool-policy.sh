#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
RULES_PATH="${REPO_ROOT}/.github/hooks/policy-rules.tsv"

# The harness delivers the tool call as JSON on stdin. Argv stays supported so
# the policy can still be exercised by hand and by check-hook-policy.
collect_input() {
  if [[ "$#" -gt 0 ]]; then
    printf '%s\n' "$*"
  fi
  if [[ ! -t 0 ]]; then
    cat
  fi
}

RAW_INPUT="$(collect_input "$@")"

# Flatten JSON punctuation to spaces so anchors such as (^|\s) still match a
# command that arrives inside a JSON string value.
INPUT="$(printf '%s' "${RAW_INPUT}" | tr '{}\[\]",' ' ')"

deny() {
  local reason="$1"
  local safer="$2"
  printf '{"permissionDecision":"deny","permissionDecisionReason":"%s %s"}\n' "${reason}" "${safer}"
  echo "[BLOCKED] ${reason}" >&2
  echo "Safer alternative: ${safer}" >&2
  # Exit 2 is an explicit deny for preToolUse, and denies even if stdout is ignored.
  exit 2
}

if [[ -f "${RULES_PATH}" ]]; then
  while IFS=$'\t' read -r pattern reason safer || [[ -n "${pattern:-}" ]]; do
    if [[ -z "${pattern}" ]] || [[ "${pattern}" == \#* ]]; then
      continue
    fi

    if echo "$INPUT" | grep -Pqi "${pattern}"; then
      deny "${reason}" "${safer}"
    fi
  done < "${RULES_PATH}"
else
  if echo "$INPUT" | grep -Pqi '(^|\s)rm\s+-rf(\s|$)'; then
    deny "Destructive recursive delete is blocked." "Use targeted file deletion with explicit paths and code review."
  fi

  if echo "$INPUT" | grep -Pqi '(^|\s)del\s+/s\s+/q(\s|$)'; then
    deny "Silent recursive delete is blocked." "Use Remove-Item with explicit files and -WhatIf first."
  fi

  if echo "$INPUT" | grep -Pqi 'curl\s+[^|]*\|\s*(bash|sh)'; then
    deny "Piped remote script execution is blocked." "Download script, inspect it, then run with explicit checksum verification."
  fi

  if echo "$INPUT" | grep -Pqi '(invoke-webrequest|irm|curl)\s+[^|;]*\|\s*(invoke-expression|iex)'; then
    deny "Remote content execution via Invoke-Expression is blocked." "Save remote content to a file, inspect it, and run only trusted code."
  fi

  if echo "$INPUT" | grep -Pqi '\.env.*(sk-[a-z0-9]{20,}|ghp_[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----|token\s*=\s*[^\s]+)'; then
    deny "Potential real secret write to .env is blocked." "Use placeholder values and inject real secrets through secure environment management."
  fi
fi

# The engine owns stage and write-set policy. It is consulted only when a run
# exists, so ordinary editing never pays for the call and never fails on it.
engine_gate() {
  local state_dir="${REPO_ROOT}/.agentic/state"
  local engine="${REPO_ROOT}/.github/scripts/agentic_engine.py"
  local python_bin engine_out

  if [[ ! -d "${state_dir}" || ! -f "${engine}" ]]; then
    return 0
  fi

  python_bin="$(command -v python3 || command -v python || true)"
  if [[ -z "${python_bin}" ]]; then
    printf '{"permissionDecision":"deny","permissionDecisionReason":"a run is active but no Python interpreter is available to gate it"}\n'
    echo "[BLOCKED] a run is active but no Python interpreter is available to gate it" >&2
    exit 2
  fi

  if ! engine_out="$(printf '%s' "${RAW_INPUT}" | "${python_bin}" "${engine}" check-tool 2>&1)"; then
    case "${engine_out}" in
      \{*) printf '%s\n' "${engine_out}" ;;
      *)
        echo "[BLOCKED] engine gate failed: ${engine_out}" >&2
        printf '{"permissionDecision":"deny","permissionDecisionReason":"engine gate failed for an active run"}\n'
        ;;
    esac
    exit 2
  fi
}

engine_gate

exit 0
