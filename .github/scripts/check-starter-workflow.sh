#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

scripts=(
  ".github/scripts/check-starter-skills.sh"
  ".github/scripts/check-approval-gated-orchestration.sh"
)

for relative_path in "${scripts[@]}"; do
  full_path="${REPO_ROOT}/${relative_path}"
  if [[ ! -f "${full_path}" ]]; then
    echo "[ERROR] Missing check script: ${relative_path}" >&2
    exit 1
  fi

  "${full_path}" "${REPO_ROOT}"
done

echo "Starter workflow checks passed."