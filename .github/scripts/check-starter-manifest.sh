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
elif version == "0.0.0":
    errors.append("starter-modules.json version must not stay at 0.0.0")
else:
    # The guide also requires a changelog entry for every manifest change. A
    # bump with no recorded entry is untraceable, and that is the one part of
    # the versioning contract a stateless check can actually hold: whether a
    # bump was warranted cannot be known without the previous manifest, but
    # whether the current version is documented can.
    changelog_path = repo_root / "CHANGELOG.md"
    if changelog_path.is_file():
        try:
            changelog_text = changelog_path.read_text(encoding="utf-8")
        except OSError as exc:
            errors.append(f"CHANGELOG.md cannot be read: {exc}")
        else:
            # Scope the search to Summary lines. A substring match over the whole
            # file is satisfied by the version being quoted anywhere, including
            # in a validation note about this very check, which makes the rule
            # unfalsifiable.
            #
            # The guards below have to survive prose. The first version of this used
            # (?![\d.]) and so rejected "at version 1.0.0." -- the most natural way to
            # end the sentence -- while accepting "1.0.0-beta", which is a different
            # version. A gate that turns on punctuation is arbitrary, and this one
            # failed the documented initialization path because of a full stop.
            version_pattern = re.compile(
                r"^- Summary:.*(?<![\d.])" + re.escape(version)
                + r"(?![0-9A-Za-z])(?!\.[0-9])(?!-[0-9A-Za-z])(?!\+[0-9A-Za-z])",
                re.MULTILINE,
            )
            if not version_pattern.search(changelog_text):
                errors.append(
                    f"starter-modules.json version {version} is not recorded in a "
                    "CHANGELOG.md Summary line; describe the manifest change there"
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
# four ADRs and the runbook index were missing this way.
#
# The reverse scan only makes sense in the repository that maintains the starter.
# An adopting repository legitimately owns files in these directories, so running
# the scan there would report the adopter's own ADRs, runbooks, and agents as
# violations. `maintainerAssetScan` is that switch: true in the starter, false in
# an adopting repo. It is required rather than defaulted so neither case is silent.
scan_setting = manifest.get("maintainerAssetScan")
if not isinstance(scan_setting, bool):
    errors.append(
        "starter-modules.json must set maintainerAssetScan to true (starter) or "
        "false (adopting repository)"
    )
elif scan_setting:
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

# The README states this repository's size in fourteen places and every one was
# typed by hand. Nothing derived them, so the engine-test badge read 62 while the
# suite ran 156 and the module count was off by one in two places. A count nobody
# checks is a comment, so each claim below is compared with the tree that produces
# it. Same switch as the scan above: these numbers describe the starter's own
# README, which an adopting repository replaces.
if scan_setting:
    readme_path = repo_root / "README.md"
    if readme_path.is_file():
        readme_text = readme_path.read_text(encoding="utf-8")

        def count_glob(directory: pathlib.Path, pattern: str) -> int:
            return len(list(directory.glob(pattern))) if directory.is_dir() else 0

        skills_dir = repo_root / ".github/skills"
        engine_path = repo_root / ".github/scripts/agentic_engine.py"
        derived = {
            "instructions": count_glob(repo_root / ".github/instructions", "*.md"),
            "skills": len(
                [d for d in skills_dir.iterdir() if (d / "SKILL.md").is_file()]
            ) if skills_dir.is_dir() else 0,
            "agents": count_glob(repo_root / ".github/agents", "*.md"),
            "prompts": count_glob(repo_root / ".github/prompts", "*.md"),
            "evals": count_glob(repo_root / "evals/tasks", "*"),
            # The umbrella runs the others, so it is not one of the contracts.
            "checks": count_glob(repo_root / ".github/scripts", "check-*.sh") - 1,
            "modules": len(modules),
            "engine": len(
                re.findall(
                    r"^\s+def test_",
                    engine_path.read_text(encoding="utf-8"),
                    re.MULTILINE,
                )
            ) if engine_path.is_file() else 0,
        }

        claims = [
            ("skills badge", "skills", r"skills-(\d+)-blue"),
            ("agents badge", "agents", r"agents-(\d+)-blue"),
            ("prompts badge", "prompts", r"prompts-(\d+)-blue"),
            ("checks badge", "checks", r"checks-(\d+)%2F\d+"),
            ("engine-test badge", "engine", r"engine%20tests-(\d+)-"),
            ("instructions table row", "instructions", r"\|\s*\*\*Instructions\*\*\s*\|\s*(\d+)\s*\|"),
            ("skills table row", "skills", r"\|\s*\*\*Skills\*\*\s*\|\s*(\d+)\s*\|"),
            ("agents table row", "agents", r"\|\s*\*\*Agents\*\*\s*\|\s*(\d+)\s*\|"),
            ("prompts table row", "prompts", r"\|\s*\*\*Prompts\*\*\s*\|\s*(\d+)\s*\|"),
            ("evals table row", "evals", r"\|\s*\*\*Evals\*\*\s*\|\s*(\d+)\s*\|"),
            ("guardrails table row", "checks", r"\|\s*\*\*Guardrails\*\*\s*\|\s*(\d+) checks"),
            ("module count in the manifest paragraph", "modules", r"(\d+) modules across core, optional, and overlay"),
            ("module count in the directory tree", "modules", r"what ships enabled \((\d+) modules\)"),
            ("self-test count in the loop paragraph", "engine", r"state machine with (\d+) self-tests"),
        ]
        for label, key, pattern in claims:
            match = re.search(pattern, readme_text)
            if match is None:
                # A wording change is not a failure of the repository, but it is a
                # lost assertion. Say so rather than passing silently.
                errors.append(
                    f"README.md no longer states the {label} in the expected form; "
                    "update this check with the new wording instead of dropping it"
                )
                continue
            claimed = int(match.group(1))
            if claimed != derived[key]:
                errors.append(
                    f"README.md {label} says {claimed}; the repository has "
                    f"{derived[key]}"
                )

# app/README.md states that until its verification block is replaced it describes a
# scaffold rather than a project. Nothing read that sentence, so an app folder full of
# code could keep pointing at a placeholder command while every gate reported green.
#
# The rule fires on a state transition rather than on a declaration, because a declared
# "initialized: true" can be wrong and a folder's contents cannot. The starter itself is
# unaffected: its app folder holds only that README, so the rule never reaches it.
app_dir = repo_root / "app"
app_readme = app_dir / "README.md"
app_placeholder = "<the command that runs this project's tests>"
if app_dir.is_dir() and app_readme.is_file():
    app_code = [p for p in app_dir.rglob("*") if p.is_file() and p != app_readme]
    if app_code and app_placeholder in app_readme.read_text(encoding="utf-8"):
        errors.append(
            f"app/README.md still carries the placeholder verification command while app/ "
            f"holds {len(app_code)} file(s) of code; replace it with the command the tests "
            "actually run, so verify has something real to execute"
        )

# docs/prd.md ships as a template whose provenance row reads `docs/inputs/<intake>.md`.
# Nothing read that row either, so a project could route an intake, leave the PRD as a
# template, and still pass every gate with a template as its stated source of truth.
#
# The trigger is derived from the row rather than from a flag: a template keeps a
# placeholder in its Source field and a routed PRD names a document, so the difference is
# observable. That also survives deferral, because a document the router declined never
# reaches the row.
prd_path = repo_root / "docs/prd.md"
if prd_path.is_file():
    prd_text = prd_path.read_text(encoding="utf-8")
    source_row = re.search(r"(?m)^\|\s*Source\s*\|\s*(.+?)\s*\|\s*$", prd_text)
    if source_row:
        source_value = source_row.group(1).strip().strip("`").strip()
        if "<" not in source_value:
            if "/" in source_value or source_value.lower().endswith(".md"):
                candidates = [
                    repo_root / source_value,
                    repo_root / "docs" / "inputs" / source_value,
                ]
                if not any(candidate.is_file() for candidate in candidates):
                    errors.append(
                        f"docs/prd.md names its source as {source_value!r}, but that file "
                        "exists neither at that path nor under docs/inputs/"
                    )
            remaining = re.findall(r"<[^<>\n]+>", prd_text)
            if remaining:
                errors.append(
                    "docs/prd.md names a concrete source but still contains template "
                    f"placeholders such as {remaining[0]!r}; fill them in, or put the "
                    "Source row back to the template value if nothing has been routed yet"
                )

# docs/inputs.md is the intake index: the router is meant to record every document it
# routes. Nothing compared it with the directory, so a document could sit in
# docs/inputs/ unread while every gate passed -- which is precisely what "I handed this
# repository a PRD and got nothing back" looks like from the inside.
#
# The rule points one way on purpose: every intake must be acknowledged in the index. The
# reverse, an index row naming a file that is gone, is deliberately not asserted, because
# the shipped rows are fictional examples and exempting them by name would open a hole a
# real document could be renamed into.
inputs_dir = repo_root / "docs" / "inputs"
inputs_index = repo_root / "docs" / "inputs.md"
if inputs_dir.is_dir() and inputs_index.is_file():
    index_text = inputs_index.read_text(encoding="utf-8")
    # A plain substring test is not enough: the index mentions `docs/design-brief.md`, so
    # an intake called `brief.md` appeared logged when it was not. The lookarounds keep a
    # name from matching inside a longer one.
    unlogged = [
        entry.name
        for entry in sorted(inputs_dir.iterdir(), key=lambda item: item.name)
        if entry.is_file()
        and entry.name != "README.md"
        and not re.search(
            r"(?<![\w.-])" + re.escape(entry.name) + r"(?![\w.-])", index_text
        )
    ]
    if unlogged:
        errors.append(
            "docs/inputs/ holds intake document(s) that docs/inputs.md never mentions: "
            + ", ".join(unlogged)
            + "; route them with route-project-inputs so the decision is recorded"
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