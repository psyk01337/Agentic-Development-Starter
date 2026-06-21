#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

scripts=(
  ".github/scripts/check-starter-manifest.sh"
  ".github/scripts/check-starter-skills.sh"
  ".github/scripts/check-agent-contracts.sh"
  ".github/scripts/check-approval-gated-orchestration.sh"
  ".github/scripts/check-hook-policy.sh"
  ".github/scripts/check-prompt-contracts.sh"
  ".github/scripts/check-mcp-posture.sh"
  ".github/scripts/check-markdown-quality.sh"
  ".github/scripts/check-evals.sh"
)

total_start=$(date +%s)
total_time=0

for relative_path in "${scripts[@]}"; do
  full_path="${REPO_ROOT}/${relative_path}"
  if [[ ! -f "${full_path}" ]]; then
    echo "[ERROR] Missing check script: ${relative_path}" >&2
    exit 1
  fi

  script_start=$(date +%s)
  bash "${full_path}" "${REPO_ROOT}"
  script_end=$(date +%s)
  script_time=$((script_end - script_start))
  total_time=$((total_time + script_time))
  
  script_name=$(basename "${relative_path}")
  echo "  ✓ ${script_name} (${script_time}s)"
done

total_end=$(date +%s)
total_elapsed=$((total_end - total_start))

echo ""
echo "Starter workflow checks passed."
echo "Total time: ${total_elapsed}s"