#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
MANIFEST_PATH="${REPO_ROOT}/.github/starter-modules.json"

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  echo "[ERROR] Missing required file: .github/starter-modules.json" >&2
  exit 1
fi

python3 - "${MANIFEST_PATH}" "${REPO_ROOT}" <<'PY'
import json
import pathlib
import re
import sys

manifest_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
errors = []

try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"[ERROR] starter-modules.json is not valid JSON: {exc}", file=sys.stderr)
    sys.exit(1)

modules = manifest.get("modules")
if not isinstance(modules, list) or not modules:
    errors.append("starter-modules.json must contain a non-empty modules array")

# The versioning guide requires semantic X.Y.Z and a major bump whenever a
# module loses a file path, including a rename. Nothing enforced the shape, so
# two-part versions drifted in unnoticed.
version = manifest.get("version")
if not isinstance(version, str) or not re.fullmatch(r"\d+\.\d+\.\d+", version):
    errors.append(
        f"starter-modules.json version must be semantic X.Y.Z; found {version!r}"
    )

seen_ids = set()
required_core_files = {
    ".github/copilot-instructions.md",
    ".github/instructions/core.instructions.md",
    ".github/instructions/security.instructions.md",
    ".github/instructions/memory.instructions.md",
    ".github/starter-modules.json",
}
seen_files = set()

for module in modules or []:
    module_id = module.get("id")
    if not module_id:
        errors.append("Module is missing id")
    elif module_id in seen_ids:
        errors.append(f"Duplicate module id: {module_id}")
    else:
        seen_ids.add(module_id)

    if module.get("kind") not in {"core", "optional", "overlay"}:
        errors.append(f"Module {module_id or '<missing>'} has invalid kind")

    if not isinstance(module.get("defaultEnabled"), bool):
        errors.append(f"Module {module_id or '<missing>'} must set boolean defaultEnabled")

    files = module.get("files")
    if not isinstance(files, list) or not files:
        errors.append(f"Module {module_id or '<missing>'} must contain non-empty files")
        continue

    for relative_path in files:
        if not isinstance(relative_path, str) or not relative_path.strip():
            errors.append(f"Module {module_id or '<missing>'} contains an invalid file path")
            continue
        seen_files.add(relative_path)
        if not (repo_root / relative_path).exists():
            errors.append(f"Manifest-listed file does not exist: {relative_path}")

# Instruction files must declare applyTo, or they never load predictably.
for relative_path in sorted(seen_files):
    if not relative_path.endswith(".instructions.md"):
        continue
    instruction_path = repo_root / relative_path
    if not instruction_path.is_file():
        continue
    try:
        content = instruction_path.read_text(encoding="utf-8")
    except OSError as exc:
        errors.append(f"Instruction file cannot be read: {relative_path} ({exc})")
        continue
    if not content.startswith("---"):
        errors.append(f"Instruction file must start with YAML frontmatter: {relative_path}")
        continue
    closing = content.find("\n---", 3)
    frontmatter = content[:closing] if closing != -1 else ""
    if "applyTo:" not in frontmatter:
        errors.append(f"Instruction file is missing applyTo: {relative_path}")

# The manifest above is checked manifest-to-disk. Without the reverse direction a
# new asset simply never ships when its module is adopted, and nothing notices:
# four ADRs and the runbook index were missing this way. Only directories that
# hold module assets are scanned, so root tooling stays out of scope.
asset_dirs = [
    ".github/agents",
    ".github/prompts",
    ".github/skills",
    ".github/instructions",
    ".github/schema",
    ".github/examples",
    ".github/scripts",
    ".github/roles",
    ".github/hooks",
    ".github/workflows",
    ".vscode",
    "docs/adr",
    "docs/runbooks",
    "evals/tasks",
    "evals/expected",
]
generated_markers = ("__pycache__", ".pytest_cache", ".mypy_cache")
for relative_dir in asset_dirs:
    base = repo_root / relative_dir
    if not base.is_dir():
        continue
    for candidate in sorted(base.rglob("*")):
        if not candidate.is_file():
            continue
        parts = candidate.relative_to(repo_root).parts
        if any(marker in parts for marker in generated_markers):
            continue
        if relative_dir == ".github/hooks" and parts[:3] == (".github", "hooks", "logs"):
            continue
        relative_path = candidate.relative_to(repo_root).as_posix()
        if relative_path not in seen_files:
            errors.append(
                f"Asset is not listed in starter-modules.json: {relative_path}"
            )

missing_core = sorted(required_core_files - seen_files)
for relative_path in missing_core:
    errors.append(f"Required core file is not listed in starter-modules.json: {relative_path}")

if errors:
    for error in errors:
        print(f"[ERROR] {error}", file=sys.stderr)
    sys.exit(1)

print("Starter manifest check passed.")
PY