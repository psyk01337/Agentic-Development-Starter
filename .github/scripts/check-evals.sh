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

required_files=(
  "evals/README.md"
  "evals/tasks/simple-bugfix.md"
  "evals/tasks/add-api-endpoint.md"
  "evals/tasks/frontend-component.md"
  "evals/tasks/security-review.md"
  "evals/tasks/update-docs-and-changelog.md"
  "evals/tasks/debug-failing-ci.md"
  "evals/tasks/laravel-component.md"
  "evals/expected/simple-bugfix.checklist.md"
  "evals/expected/add-api-endpoint.checklist.md"
  "evals/expected/frontend-component.checklist.md"
  "evals/expected/security-review.checklist.md"
  "evals/expected/laravel-component.checklist.md"
  "evals/run-evals.sh"
  "evals/run-evals.ps1"
)

for relative_path in "${required_files[@]}"; do
  if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
    report_error "Missing eval harness file: ${relative_path}"
  fi
done

if [[ -f "${REPO_ROOT}/evals/README.md" ]] && ! grep -Fq "manual/semi-automated" "${REPO_ROOT}/evals/README.md"; then
  report_error "Eval README must document the manual/semi-automated harness model."
fi

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Eval harness checks passed."