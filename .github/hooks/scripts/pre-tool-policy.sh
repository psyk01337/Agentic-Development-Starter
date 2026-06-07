#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
RULES_PATH="${REPO_ROOT}/.github/hooks/policy-rules.tsv"
INPUT="${*:-}"

deny() {
  local reason="$1"
  local safer="$2"
  echo "[BLOCKED] ${reason}" >&2
  echo "Safer alternative: ${safer}" >&2
  exit 1
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

exit 0
