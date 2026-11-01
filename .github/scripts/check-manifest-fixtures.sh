#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

# check-starter-manifest carries rules that only fire once the repository has already drifted:
# a stale count, an unlogged intake, a check nobody runs. On a clean repository they are
# invisible, so a regression in one of them would ship silently. That is the same "a guardrail
# nobody checks is a comment" problem, one level up.
#
# Each case copies the working tree, breaks exactly one thing, runs the check, and requires the
# expected message. A fresh copy per case means a crash here cannot leave anything mutated.
python3 - "${REPO_ROOT}" <<'PY'
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

repo_root = pathlib.Path(sys.argv[1]).resolve()
ignore = shutil.ignore_patterns(".git", ".forlocal", ".agentic", "__pycache__")


def mutate_readme_badge(tree):
    path = tree / "README.md"
    path.write_text(
        path.read_text(encoding="utf-8").replace("engine%20tests-", "engine%20tests-9"),
        encoding="utf-8",
    )
    return "engine-test badge"


def mutate_app_placeholder(tree):
    (tree / "app/src").mkdir(parents=True, exist_ok=True)
    (tree / "app/src/probe.js").write_text("export const probe = 1;\n", encoding="utf-8")
    return "placeholder verification command"


def mutate_intake(tree):
    (tree / "docs/inputs").mkdir(parents=True, exist_ok=True)
    (tree / "docs/inputs/probe-intake.md").write_text("# probe\n", encoding="utf-8")
    return "never mentions"


def mutate_prd_source(tree):
    (tree / "docs/inputs").mkdir(parents=True, exist_ok=True)
    (tree / "docs/inputs/probe-intake.md").write_text("# probe\n", encoding="utf-8")
    prd = tree / "docs/prd.md"
    prd.write_text(
        re.sub(
            r"(?m)^\|\s*Source\s*\|.*$",
            "| Source | `docs/inputs/probe-intake.md` |",
            prd.read_text(encoding="utf-8"),
            count=1,
        ),
        encoding="utf-8",
    )
    return "names a concrete source"


def mutate_umbrella(tree):
    (tree / ".github/scripts/check-loose.sh").write_text(
        "#!/usr/bin/env bash\nexit 0\n", encoding="utf-8"
    )
    return "never runs them"


cases = [
    ("baseline passes", None),
    ("a wrong README badge is caught", mutate_readme_badge),
    ("code behind a placeholder command is caught", mutate_app_placeholder),
    ("an unlogged intake is caught", mutate_intake),
    ("a templated PRD with a concrete source is caught", mutate_prd_source),
    ("a check the umbrella never runs is caught", mutate_umbrella),
]

failures = []
with tempfile.TemporaryDirectory(prefix="manifest-fixtures-") as workdir:
    for index, (label, mutate) in enumerate(cases):
        tree = pathlib.Path(workdir) / f"case-{index}"
        shutil.copytree(repo_root, tree, ignore=ignore, symlinks=True)

        marker = mutate(tree) if mutate is not None else None
        result = subprocess.run(
            ["bash", str(tree / ".github/scripts/check-starter-manifest.sh"), str(tree)],
            capture_output=True,
            text=True,
        )
        output = result.stdout + result.stderr

        if mutate is None:
            ok = result.returncode == 0
            detail = "" if ok else f"exit {result.returncode}: {(output.strip().splitlines() or [''])[0]}"
        else:
            ok = result.returncode != 0 and marker in output
            state = "present" if marker in output else "absent"
            detail = "" if ok else f"exit {result.returncode}, marker {marker!r} {state}"

        print(f"{'ok  ' if ok else 'FAIL'} {label}")
        if not ok:
            failures.append(f"{label}: {detail}")

        shutil.rmtree(tree, ignore_errors=True)

if failures:
    for failure in failures:
        print(f"[ERROR] {failure}", file=sys.stderr)
    raise SystemExit(1)

print("Manifest fixture checks passed.")
PY
