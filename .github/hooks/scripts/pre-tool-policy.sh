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
  while IFS=$'\t' read -r pattern reason safer; do
    if [[ -z "${pattern}" ]] || [[ "${pattern}" == \#* ]]; then
      continue
    fi

    if echo "$INPUT" | grep -Eqi "${pattern}"; then
      deny "${reason}" "${safer}"
    fi
  done < "${RULES_PATH}"
else
  if echo "$INPUT" | grep -Eqi '(^|[[:space:]])rm[[:space:]]+-rf([[:space:]]|$)'; then
    deny "Destructive recursive delete is blocked." "Use targeted file deletion with explicit paths and code review."
  fi

  if echo "$INPUT" | grep -Eqi '(^|[[:space:]])del[[:space:]]+/s[[:space:]]+/q([[:space:]]|$)'; then
    deny "Silent recursive delete is blocked." "Use Remove-Item with explicit files and -WhatIf first."
  fi

  if echo "$INPUT" | grep -Eqi 'curl[[:space:]]+[^|]*\|[[:space:]]*(bash|sh)'; then
    deny "Piped remote script execution is blocked." "Download script, inspect it, then run with explicit checksum verification."
  fi

  if echo "$INPUT" | grep -Eqi '(invoke-webrequest|irm|curl)[[:space:]]+[^|;]*\|[[:space:]]*(invoke-expression|iex)'; then
    deny "Remote content execution via Invoke-Expression is blocked." "Save remote content to a file, inspect it, and run only trusted code."
  fi

  if echo "$INPUT" | grep -Eqi '\.env.*(sk-[a-z0-9]{20,}|ghp_[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----|token[[:space:]]*=[[:space:]]*[^[:space:]]+)'; then
    deny "Potential real secret write to .env is blocked." "Use placeholder values and inject real secrets through secure environment management."
  fi
fi

exit 0
