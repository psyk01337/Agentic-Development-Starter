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
declare -A manifest_skill_paths=()

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  report_error "Missing required file: .github/starter-modules.json"
else
  mapfile -t skill_paths < <(grep -oE '"\.github/skills/[^[:space:]"]+/SKILL\.md"' "${MANIFEST_PATH}" | sed 's/^"//; s/"$//' | sort -u)

  for relative_path in "${skill_paths[@]}"; do
    manifest_skill_paths["${relative_path}"]=1
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

SKILLS_ROOT="${REPO_ROOT}/.github/skills"
if [[ ! -d "${SKILLS_ROOT}" ]]; then
  report_error "Missing required directory: .github/skills"
else
  while IFS= read -r -d '' skill_dir; do
    skill_name="$(basename "${skill_dir}")"
    relative_path=".github/skills/${skill_name}/SKILL.md"
    skill_file="${skill_dir}/SKILL.md"

    if [[ ! "${skill_name}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      report_error "Skill directory must be lowercase hyphenated: .github/skills/${skill_name}"
    fi

    if [[ ! -f "${skill_file}" ]]; then
      report_error "Missing skill file: ${relative_path}"
      continue
    fi

    if [[ -f "${MANIFEST_PATH}" && -z "${manifest_skill_paths[${relative_path}]:-}" ]]; then
      report_error "Skill file is not referenced in starter-modules.json: ${relative_path}"
    fi

    first_line="$(head -n 1 "${skill_file}" | tr -d '\r')"
    if [[ "${first_line}" != "---" ]]; then
      report_error "Skill file must start with YAML frontmatter: ${relative_path}"
      continue
    fi

    frontmatter="$(awk '{ sub(/\r$/, "") } NR == 1 { next } /^---$/ { exit } { print }' "${skill_file}")"
    frontmatter_name="$(printf '%s\n' "${frontmatter}" | awk -F': *' '$1 == "name" { print $2; exit }')"
    frontmatter_description="$(printf '%s\n' "${frontmatter}" | awk -F': *' '$1 == "description" { print $2; exit }')"

    if [[ -z "${frontmatter_name}" ]]; then
      report_error "Skill frontmatter is missing name: ${relative_path}"
    elif [[ ! "${frontmatter_name}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      report_error "Skill frontmatter name must be lowercase hyphenated: ${relative_path}"
    elif [[ "${frontmatter_name}" != "${skill_name}" ]]; then
      report_error "Skill frontmatter name must match directory name: ${relative_path}"
    fi

    if [[ -z "${frontmatter_description}" ]]; then
      report_error "Skill frontmatter is missing description: ${relative_path}"
    fi
  done < <(find "${SKILLS_ROOT}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Starter skill manifest check passed."