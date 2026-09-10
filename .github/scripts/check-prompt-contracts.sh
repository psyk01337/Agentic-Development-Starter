#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
FAILED=0

report_error() {
  local message="$1"
  echo "[ERROR] ${message}" >&2
  FAILED=1
}

required_prompts=()
MANIFEST_PATH="${REPO_ROOT}/.github/starter-modules.json"
if [[ ! -f "${MANIFEST_PATH}" ]]; then
  report_error "Missing required file: .github/starter-modules.json"
else
  mapfile -t required_prompts < <(grep -oE '"\.github/prompts/[^[:space:]"]+\.prompt\.md"' "${MANIFEST_PATH}" | sed 's/^"//; s/"$//' | sort -u)
fi

for relative_path in "${required_prompts[@]}"; do
  full_path="${REPO_ROOT}/${relative_path}"
  if [[ ! -f "${full_path}" ]]; then
    report_error "Missing prompt file: ${relative_path}"
    continue
  fi

  for heading in "Context To Inspect First" "Deliverables" "Safety Boundaries" "Expected Output"; do
    if ! tr -d '\r' < "${full_path}" | grep -Eq "^## ${heading}$"; then
      report_error "Prompt is missing heading '${heading}': ${relative_path}"
    fi
  done

  if ! grep -Eqi "stop and ask before" "${full_path}"; then
    report_error "Prompt must include destructive-change stop rule: ${relative_path}"
  fi
done

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Prompt contract checks passed."