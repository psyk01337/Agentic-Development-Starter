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

MANIFEST_PATH="${REPO_ROOT}/.github/starter-modules.json"
if [[ ! -f "${MANIFEST_PATH}" ]]; then
  report_error "Missing required file: .github/starter-modules.json"
else
  mapfile -t skill_paths < <(grep -oE '"\.github/skills/[^[:space:]"]+/SKILL\.md"' "${MANIFEST_PATH}" | sed 's/^"//; s/"$//' | sort -u)

  for relative_path in "${skill_paths[@]}"; do
    full_path="${REPO_ROOT}/${relative_path}"
    if [[ ! -f "${full_path}" ]]; then
      report_error "Missing manifest-listed skill file: ${relative_path}"
      continue
    fi

    skill_dir="$(dirname "${full_path}")"
    if [[ ! -d "${skill_dir}" ]]; then
      report_error "Missing skill directory for: ${relative_path}"
    fi

    if [[ "$(basename "${full_path}")" != "SKILL.md" ]]; then
      report_error "Unexpected skill file name for: ${relative_path}"
    fi
  done
fi

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Starter skill manifest check passed."