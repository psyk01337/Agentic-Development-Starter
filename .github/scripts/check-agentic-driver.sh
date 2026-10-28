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

DRIVER=".github/scripts/agentic_driver.py"

if [[ ! -f "${REPO_ROOT}/${DRIVER}" ]]; then
  report_error "Missing ${DRIVER}"
else
  if ! python3 "${REPO_ROOT}/${DRIVER}" selftest >/tmp/driver-selftest.$$ 2>&1; then
    report_error "Driver self-tests failed:"
    sed 's/^/    /' /tmp/driver-selftest.$$ >&2
  fi
  rm -f /tmp/driver-selftest.$$
fi

# The overlay must ship disabled. An autonomous executor that is on by default
# would give every adopter a process that can edit files and run commands.
python3 - "${REPO_ROOT}" <<'PY'
import json
import pathlib
import sys

repo_root = pathlib.Path(sys.argv[1])
errors = []
manifest_path = repo_root / ".github" / "starter-modules.json"
if not manifest_path.is_file():
    print("[ERROR] Missing .github/starter-modules.json")
    raise SystemExit(1)

modules = json.loads(manifest_path.read_text(encoding="utf-8")).get("modules", [])
overlays = [m for m in modules if m.get("id") == "overlay-autonomous-execution"]
if not overlays:
    errors.append("manifest is missing the overlay-autonomous-execution module")
else:
    module = overlays[0]
    if module.get("kind") != "overlay":
        errors.append("overlay-autonomous-execution must have kind 'overlay'")
    if module.get("defaultEnabled") is not False:
        errors.append("overlay-autonomous-execution must be default-disabled")
    listed = module.get("files", [])
    if ".github/scripts/agentic_driver.py" not in listed:
        errors.append("overlay-autonomous-execution must list the driver")

for message in errors:
    print(f"[ERROR] {message}", file=sys.stderr)
raise SystemExit(1 if errors else 0)
PY
if [[ $? -ne 0 ]]; then FAILED=1; fi

# The gateway must deny by default. A handler that permits unknown tools is a
# control in appearance only.
if ! grep -Fq 'if kind is None:' "${REPO_ROOT}/${DRIVER}"; then
  report_error "Driver no longer denies unclassified tools"
fi
if ! grep -Fq 'return self._deny(' "${REPO_ROOT}/${DRIVER}"; then
  report_error "Driver no longer has an explicit denial path"
fi

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi
echo "Agentic driver checks passed."