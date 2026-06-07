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

required_prompts=(
  ".github/prompts/onboard-existing-repo.prompt.md"
  ".github/prompts/plan-small-feature.prompt.md"
  ".github/prompts/implement-small-diff.prompt.md"
  ".github/prompts/review-current-diff.prompt.md"
  ".github/prompts/create-adr.prompt.md"
  ".github/prompts/generate-test-plan.prompt.md"
  ".github/prompts/prepare-release-notes.prompt.md"
  ".github/prompts/migrate-to-starter.prompt.md"
  ".github/prompts/security-review.prompt.md"
  ".github/prompts/debug-failing-ci.prompt.md"
)

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

  if ! grep -Eqi "stop and ask before destructive changes" "${full_path}"; then
    report_error "Prompt must include destructive-change stop rule: ${relative_path}"
  fi
done

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Prompt contract checks passed."