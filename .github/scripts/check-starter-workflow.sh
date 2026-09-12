#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

scripts=(
  ".github/scripts/check-starter-manifest.sh"
  ".github/scripts/check-starter-skills.sh"
  ".github/scripts/check-agent-contracts.sh"
  ".github/scripts/check-approval-gated-orchestration.sh"
  ".github/scripts/check-supervisor-orchestration.sh"
  ".github/scripts/check-hook-policy.sh"
  ".github/scripts/check-prompt-contracts.sh"
  ".github/scripts/check-mcp-posture.sh"
  ".github/scripts/check-markdown-quality.sh"
  ".github/scripts/check-evals.sh"
)

total_start=$(date +%s)
total_time=0
failure_count=0
failed_scripts=()

for relative_path in "${scripts[@]}"; do
  full_path="${REPO_ROOT}/${relative_path}"
  script_name=$(basename "${relative_path}")

  if [[ ! -f "${full_path}" ]]; then
    echo "[ERROR] Missing check script: ${relative_path}" >&2
    failure_count=$((failure_count + 1))
    failed_scripts+=("${relative_path}")
    continue
  fi

  script_start=$(date +%s)
  set +e
  bash "${full_path}" "${REPO_ROOT}"
  script_status=$?
  set -e
  script_end=$(date +%s)
  script_time=$((script_end - script_start))
  total_time=$((total_time + script_time))
  
  if [[ "${script_status}" -ne 0 ]]; then
    echo "  ✗ ${script_name} (${script_time}s)" >&2
    failure_count=$((failure_count + 1))
    failed_scripts+=("${relative_path}")
  else
    echo "  ✓ ${script_name} (${script_time}s)"
  fi
done

total_end=$(date +%s)
total_elapsed=$((total_end - total_start))

echo ""

if [[ "${failure_count}" -ne 0 ]]; then
  for relative_path in "${failed_scripts[@]}"; do
    echo "[ERROR] Check failed: ${relative_path}" >&2
  done
  echo "Starter workflow checks failed: ${failure_count} of ${#scripts[@]} checks reported failures." >&2
  exit 1
fi

echo "Starter workflow checks passed."
echo "Total time: ${total_elapsed}s"