#!/usr/bin/env bash
set -euo pipefail

INPUT="${*:-}"

deny() {
  local reason="$1"
  local safer="$2"
  echo "[BLOCKED] ${reason}" >&2
  echo "Safer alternative: ${safer}" >&2
  exit 1
}

if echo "$INPUT" | grep -Eqi '(^|[[:space:]])rm[[:space:]]+-rf([[:space:]]|$)'; then
  deny "Destructive recursive delete is blocked." "Use targeted file deletion with explicit paths and code review."
fi

if echo "$INPUT" | grep -Eqi '(^|[[:space:]])del[[:space:]]+/s[[:space:]]+/q([[:space:]]|$)'; then
  deny "Silent recursive delete is blocked." "Use explicit deletes and dry-run steps first."
fi

if echo "$INPUT" | grep -Eqi 'curl[[:space:]]+[^|]*\|[[:space:]]*(bash|sh)'; then
  deny "Piped remote script execution is blocked." "Download, inspect, checksum-verify, then run explicitly."
fi

if echo "$INPUT" | grep -Eqi '(invoke-webrequest|irm|curl)[[:space:]]+[^|;]*\|[[:space:]]*(invoke-expression|iex)'; then
  deny "Remote content execution via Invoke-Expression is blocked." "Save remote content to a file, inspect, then run trusted code only."
fi

if echo "$INPUT" | grep -Eqi '\.env.*(sk-[a-z0-9]{20,}|ghp_[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----|token[[:space:]]*=[[:space:]]*[^[:space:]]+)'; then
  deny "Potential real secret write to .env is blocked." "Use placeholder values and secure environment injection for real secrets."
fi

exit 0
