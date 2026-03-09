#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
FAILED=0

report_missing() {
  local message="$1"
  echo "[ERROR] ${message}" >&2
  FAILED=1
}

assert_file_exists() {
  local relative_path="$1"
  if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
    report_missing "Missing required file: ${relative_path}"
  fi
}

assert_file_contains() {
  local relative_path="$1"
  local pattern="$2"
  local description="$3"

  if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
    report_missing "Cannot verify ${description} because file is missing: ${relative_path}"
    return
  fi

  if ! grep -Eq "${pattern}" "${REPO_ROOT}/${relative_path}"; then
    report_missing "Missing expected content for ${description} in ${relative_path}"
  fi
}

required_files=(
  ".github/agents/orchestration-coordinator.agent.md"
  ".github/skills/approval-gated-handoffs/SKILL.md"
  ".github/schema/approval-gated-handoff-envelope.schema.json"
  ".github/examples/approval-gated-handoffs/approved-tech-planner-to-senior-software-engineer.json"
  ".github/examples/approval-gated-handoffs/pending-architecture-reviewer-to-senior-software-engineer.json"
  ".github/examples/approval-gated-handoffs/rejected-qa-to-senior-software-engineer.json"
  ".github/examples/approval-gated-handoffs/stale-analyst-to-tech-planner.json"
  ".github/scripts/check-approval-gated-orchestration.ps1"
  ".github/scripts/check-approval-gated-orchestration.sh"
  "docs/runbooks/approval-gated-handoffs.md"
  "docs/adr/0001-approval-gated-orchestration-overlay.md"
)

for relative_path in "${required_files[@]}"; do
  assert_file_exists "${relative_path}"
done

assert_file_contains ".github/starter-modules.json" "overlay-approval-gated-orchestration" "overlay module id"
assert_file_contains ".github/starter-modules.json" "approval-gated-handoff-envelope\.schema\.json" "schema manifest entry"
assert_file_contains ".github/AGENTS.md" "Inputs for next agent" "core handoff contract extension"
assert_file_contains ".github/AGENTS.md" "Decision status" "decision status field"
assert_file_contains ".github/AGENTS.md" "overlay-only" "overlay-only orchestration wording"
assert_file_contains "docs/runbooks/approval-gated-handoffs.md" "approval-gated-handoff-envelope\.schema\.json" "schema reference"
assert_file_contains "docs/runbooks/approval-gated-handoffs.md" "jsonschema|ajv-cli" "schema validation note"
assert_file_contains "docs/runbooks/hooks.md" "postToolUse" "audit seam reuse guidance"
assert_file_contains "docs/adr/0001-approval-gated-orchestration-overlay.md" "default-disabled orchestration overlay" "ADR decision wording"

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Approval-gated orchestration overlay check passed."