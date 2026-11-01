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

if [[ ! -f "${REPO_ROOT}/.github/scripts/agentic_engine.py" ]]; then
  report_error "Missing engine: .github/scripts/agentic_engine.py"
  exit 1
fi

if ! python3 - "${REPO_ROOT}" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
policy = json.loads((root / ".github/roles/orchestration-policy.json").read_text(encoding="utf-8"))
retry = policy.get("retryPolicy")
errors = []

# This repository is a stack-agnostic boilerplate, so the shipped allowlist must not
# quietly admit only one ecosystem. Each name below stands for a family a project could
# legitimately choose; dropping one blocks that whole family from ever reaching VERIFIED,
# and nothing else would notice.
verification = policy.get("verificationCommands")
families = {
    "node": "JavaScript/TypeScript",
    "python": "Python",
    "go": "Go",
    "cargo": "Rust",
    "dotnet": ".NET",
    "mvn": "JVM",
    "ruby": "Ruby",
    "php": "PHP",
}
if not isinstance(verification, list) or not verification:
    errors.append("orchestration-policy.json must declare a non-empty verificationCommands list")
else:
    allowed_names = {str(item).strip().lower() for item in verification}
    for name, family in families.items():
        if name not in allowed_names:
            errors.append(
                f"verificationCommands no longer allows {name!r} ({family}); "
                "a project on that stack could not reach VERIFIED"
            )

if not isinstance(retry, dict):
    errors.append("orchestration-policy.json must contain a retryPolicy object")
else:
    max_repair = retry.get("maxRepairAttempts")
    threshold = retry.get("identicalFailureThreshold")
    max_verify = retry.get("maxVerifyRetries")
    if not isinstance(max_repair, int) or not 1 <= max_repair <= 10:
        errors.append("retryPolicy.maxRepairAttempts must be an integer between 1 and 10")
    if not isinstance(threshold, int) or not 1 <= threshold <= 5:
        errors.append("retryPolicy.identicalFailureThreshold must be an integer between 1 and 5")
    if isinstance(max_repair, int) and isinstance(threshold, int) and threshold > max_repair:
        errors.append("retryPolicy.identicalFailureThreshold must not exceed maxRepairAttempts")
    if not isinstance(max_verify, int) or not 0 <= max_verify <= 3:
        errors.append("retryPolicy.maxVerifyRetries must be an integer between 0 and 3")
    for flag in ("escalateOnIdenticalFailure", "escalateOnBudgetExhausted", "inconclusiveIsNeverSuccess"):
        if retry.get(flag) is not True:
            errors.append(f"retryPolicy.{flag} must be true")
    if retry.get("stateLocation") != ".agentic/state/<run-id>.json":
        errors.append("retryPolicy.stateLocation must be .agentic/state/<run-id>.json")

if not (root / ".gitignore").is_file() or ".agentic/state/" not in (root / ".gitignore").read_text(encoding="utf-8"):
    errors.append(".gitignore must ignore .agentic/state/")

if errors:
    for error in errors:
        print(f"[ERROR] {error}", file=sys.stderr)
    sys.exit(1)
PY
then
  FAILED=1
fi

if ! selftest_output="$(python3 "${REPO_ROOT}/.github/scripts/agentic_engine.py" selftest 2>&1)"; then
  report_error "agentic_engine.py selftest failed"
  printf '%s\n' "${selftest_output}" >&2
fi

if [[ ! -f "${REPO_ROOT}/.github/examples/agentic-engine/simple-feature-task.json" ]]; then
  report_error "Missing example task: .github/examples/agentic-engine/simple-feature-task.json"
fi

fixture_state="$(mktemp -d)"
cleanup() {
  rm -rf "${fixture_state}"
}
trap cleanup EXIT

if ! assert_output="$(python3 "${REPO_ROOT}/.github/scripts/agentic_engine.py" init --run-id check-fixture \
  --task "${REPO_ROOT}/.github/examples/agentic-engine/simple-feature-task.json" \
  --repo-root "${REPO_ROOT}" --state-dir "${fixture_state}" 2>&1)"; then
  report_error "Engine rejected the shipped example task"
else
  if [[ "${assert_output}" != *'"stage": "implement"'* ]]; then
    report_error "Engine did not start the example task at the implement stage"
  fi
fi

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Agentic engine checks passed."
