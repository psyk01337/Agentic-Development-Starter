#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

report_error() {
  local message="$1"
  echo "[ERROR] ${message}" >&2
  FAILED=1
}

required_files=(
  "README.md"
  "tasks/simple-bugfix.md"
  "tasks/add-api-endpoint.md"
  "tasks/frontend-component.md"
  "tasks/security-review.md"
  "tasks/update-docs-and-changelog.md"
  "tasks/debug-failing-ci.md"
  "tasks/problem-structuring.md"
  "expected/simple-bugfix.checklist.md"
  "expected/add-api-endpoint.checklist.md"
  "expected/frontend-component.checklist.md"
  "expected/security-review.checklist.md"
  "expected/problem-structuring.checklist.md"
)

for relative_path in "${required_files[@]}"; do
  if [[ ! -f "${SCRIPT_DIR}/${relative_path}" ]]; then
    report_error "Missing eval file: evals/${relative_path}"
  fi
done

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Eval harness structure is present. Available tasks:"
find "${SCRIPT_DIR}/tasks" -maxdepth 1 -name '*.md' -type f -print | sort | sed "s#${SCRIPT_DIR}/##"