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

while IFS= read -r -d '' markdown_file; do
  relative_file="${markdown_file#"${REPO_ROOT}/"}"
  if grep -nE '[[:blank:]]$' "${markdown_file}" >/tmp/starter-md-trailing.$$ 2>/dev/null; then
    while IFS= read -r line; do
      report_error "Trailing whitespace in ${relative_file}:${line%%:*}"
    done < /tmp/starter-md-trailing.$$
  fi
  rm -f /tmp/starter-md-trailing.$$

  while IFS= read -r target; do
    [[ -z "${target}" ]] && continue
    [[ "${target}" == http://* || "${target}" == https://* || "${target}" == mailto:* || "${target}" == \#* ]] && continue
    clean_target="${target%%#*}"
    clean_target="${clean_target//%20/ }"
    [[ -z "${clean_target}" ]] && continue

    if [[ "${clean_target}" = /* ]]; then
      candidate="${REPO_ROOT}${clean_target}"
    else
      candidate="$(cd "$(dirname "${markdown_file}")" && pwd)/${clean_target}"
    fi

    if [[ ! -e "${candidate}" ]]; then
      report_error "Broken local Markdown link in ${relative_file}: ${target}"
    fi
  done < <(grep -oE '\]\(([^)]+)\)' "${markdown_file}" | sed -E 's/^\]\(([^)]+)\)$/\1/')
done < <(find "${REPO_ROOT}" \( -path "${REPO_ROOT}/.git" -o -path "${REPO_ROOT}/.forlocal" \) -prune -o -name '*.md' -type f -print0)

# docs/runbooks/INDEX.md is the only way to discover a runbook, and nothing compared it with
# the directory: module-manifest-versioning.md shipped unlisted, so a reader browsing the index
# would never reach it. The reverse direction needs no rule here, because a link to a missing
# file is already reported above.
runbooks_dir="${REPO_ROOT}/docs/runbooks"
runbooks_index="${runbooks_dir}/INDEX.md"
if [[ -d "${runbooks_dir}" && -f "${runbooks_index}" ]]; then
  unlisted=()
  while IFS= read -r runbook; do
    name="$(basename "${runbook}")"
    escaped="$(printf '%s' "${name}" | sed -E 's/[][\\.^$*+?(){}|]/\\&/g')"
    if ! grep -qE "(^|[^[:alnum:]._-])${escaped}([^[:alnum:]._-]|$)" "${runbooks_index}"; then
      unlisted+=("${name}")
    fi
  done < <(find "${runbooks_dir}" -maxdepth 1 -type f -name '*.md' ! -name 'INDEX.md' | sort)
  if [[ ${#unlisted[@]} -gt 0 ]]; then
    joined="$(printf '%s, ' "${unlisted[@]}")"
    report_error "docs/runbooks/INDEX.md never names: ${joined%, }; a runbook nobody indexes is a runbook nobody reads"
  fi
fi

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Markdown quality checks passed."