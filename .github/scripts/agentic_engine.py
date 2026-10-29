#!/usr/bin/env python3
"""Deterministic orchestration engine for the Agentic Development Starter.

The engine is the control plane for a task-scoped repair loop. It never calls an
LLM. A host agent or a human asks for the next step, performs the work, and
records the result. The engine decides whether to continue, repair, or escalate.

State lives in <repo-root>/.agentic/state/<run-id>.json, which is gitignored.

Exit codes:
  0  success
  1  invalid input or invalid state transition
  3  blocked / escalated
"""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

if sys.version_info < (3, 9):
    raise SystemExit("agentic_engine.py requires Python 3.9 or newer")

RUN_ID_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,64}$")

# Directory names and suffixes that are build output rather than authored work.
# The git changed-file scan ignores them for the same reason the manifest scan
# does: importing a module here writes __pycache__, and that is not a change.
GENERATED_PATH_MARKERS = frozenset({
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    "node_modules",
    ".venv",
    "dist",
    "build",
})
GENERATED_SUFFIXES = (".pyc", ".pyo")
UNBOUNDED_WRITE_SET_ENTRIES = {
    "*",
    "**",
    "unknown",
    "broad",
    "wildcard-only",
    "tbd",
    "not-safely-bounded",
}
EVIDENCE_SCHEMES = (
    "http://",
    "https://",
    "cmd:",
    "test:",
    "commit:",
    "diff:",
    "trace:",
    "screenshot:",
    "benchmark:",
    "artifact:",
)
LOCK_STALE_SECONDS = 300
LOCK_TIMEOUT_SECONDS = 10
HISTORY_LIMIT = 200
CASE_INSENSITIVE_PATHS = os.name == "nt"
APPROVAL_CATEGORY_IDS = (
    "architecture-change",
    "core-governance-change",
    "dependency-change",
    "destructive-data-change",
    "identity-security-change",
    "production-or-deployment-change",
    "destructive-operation",
    "scope-expansion",
)

DEFAULT_RETRY_POLICY = {
    "maxRepairAttempts": 3,
    "identicalFailureThreshold": 2,
    "maxVerifyRetries": 1,
    "maxWallClockMinutes": 120,
    "escalateOnIdenticalFailure": True,
    "escalateOnBudgetExhausted": True,
    "inconclusiveIsNeverSuccess": True,
}

STAGE_ORDER = ("approval", "implement", "verify", "repair", "review", "done", "blocked")

STAGE_INSTRUCTIONS = {
    "approval": {
        "objective": "Obtain explicit human approval before any write.",
        "action": "Record approval with: approve --run-id <id> --approver <name> --note <text>",
        "requiredResult": None,
    },
    "implement": {
        "objective": "Implement the smallest slice that satisfies the acceptance criteria.",
        "action": "Record with: record --run-id <id> --stage implement --result <file>",
        "requiredResult": {
            "status": "done",
            "summary": "string",
            "implementedBy": "agent or person",
            "filesChanged": ["path"],
            "evidence": ["pointer"],
        },
    },
    "repair": {
        "objective": "Fix only the recorded blocking findings, then re-verify.",
        "action": "Record with: record --run-id <id> --stage repair --result <file>",
        "requiredResult": {
            "status": "done",
            "summary": "string",
            "implementedBy": "agent or person",
            "filesChanged": ["path"],
            "evidence": ["pointer"],
        },
    },
    "verify": {
        "objective": "Run the real verification for the touched surfaces and report the result.",
        "action": "Record with: record --run-id <id> --stage verify --result <file>",
        "requiredResult": {
            "result": "VERIFIED | NOT_VERIFIED | INCONCLUSIVE",
            "checks": [{"name": "string", "ok": True, "message": "string"}],
            "evidence": ["pointer"],
        },
    },
    "review": {
        "objective": "Review the change and return a pass or needs-revision decision.",
        "action": "Record with: record --run-id <id> --stage review --result <file>",
        "requiredResult": {
            "decision": "pass | needs-revision",
            "reviewedBy": "agent or person distinct from every implementer",
            "findings": [{"severity": "string", "summary": "string"}],
            "evidence": ["pointer"],
        },
    },
}


class EngineError(Exception):
    """Invalid input or invalid state transition."""


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="microseconds")


def emit(payload: dict) -> None:
    print(json.dumps(payload, indent=2, sort_keys=True))


def repo_root_from(script_path: Path) -> Path:
    return script_path.resolve().parent.parent.parent


def load_policy(repo_root: Path) -> dict:
    policy_path = repo_root / ".github" / "roles" / "orchestration-policy.json"
    if not policy_path.is_file():
        return {}
    try:
        return json.loads(policy_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise EngineError(f"orchestration-policy.json is not valid JSON: {exc}") from exc


def retry_policy(policy: dict) -> dict:
    configured = policy.get("retryPolicy", {}) if isinstance(policy, dict) else {}
    merged = dict(DEFAULT_RETRY_POLICY)
    for key, default in DEFAULT_RETRY_POLICY.items():
        value = configured.get(key, default)
        merged[key] = value
    return merged


def approval_categories(policy: dict) -> set:
    categories = {item.get("id") for item in policy.get("approvalRequiredCategories", []) if isinstance(item, dict)}
    return categories or set(APPROVAL_CATEGORY_IDS)


def state_dir_for(repo_root: Path, override: str | None) -> Path:
    if override:
        return Path(override).expanduser().resolve()
    return repo_root / ".agentic" / "state"


def state_path(state_dir: Path, run_id: str) -> Path:
    if not RUN_ID_PATTERN.match(run_id):
        raise EngineError("run-id must match [A-Za-z0-9._-]{1,64}")
    return state_dir / f"{run_id}.json"


def atomic_write(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_fd, tmp_name = tempfile.mkstemp(dir=str(path.parent), prefix=".tmp-", suffix=".json")
    try:
        with os.fdopen(tmp_fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)
            handle.write("\n")
        os.replace(tmp_name, path)
    finally:
        if os.path.exists(tmp_name):
            os.unlink(tmp_name)


def read_json_file(path_value: str) -> dict:
    if path_value == "-":
        raw = sys.stdin.read()
    else:
        candidate = Path(path_value).expanduser()
        if not candidate.is_file():
            raise EngineError(f"result file not found: {path_value}")
        raw = candidate.read_text(encoding="utf-8")
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise EngineError(f"result is not valid JSON: {exc}") from exc
    if not isinstance(payload, dict):
        raise EngineError("result must be a JSON object")
    return payload


def read_state_file(path: Path) -> dict:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise EngineError(f"state file is not valid JSON: {path} ({exc})") from exc
    except OSError as exc:
        raise EngineError(f"state file cannot be read: {path} ({exc})") from exc
    if not isinstance(payload, dict):
        raise EngineError(f"state file must contain a JSON object: {path}")
    return payload


def validate_state(state: dict, run_id: str) -> dict:
    for key in ("runId", "stage", "status", "task"):
        if key not in state:
            raise EngineError(f"state is missing required field '{key}'")
    if state["runId"] != run_id:
        raise EngineError(
            f"state runId {state['runId']!r} does not match requested run-id {run_id!r}"
        )
    if state["stage"] not in STAGE_ORDER:
        raise EngineError(f"state has an unknown stage: {state['stage']!r}")
    task = state["task"]
    if not isinstance(task, dict):
        raise EngineError("state task must be a JSON object")
    for key in ("taskId", "title", "acceptanceCriteria", "writeSet"):
        if key not in task:
            raise EngineError(f"state task is missing required field '{key}'")
    return state


def load_state(state_dir: Path, run_id: str) -> dict:
    path = state_path(state_dir, run_id)
    if not path.is_file():
        raise EngineError(f"no state for run-id {run_id} in {state_dir}")
    return validate_state(read_state_file(path), run_id)


def save_state(state_dir: Path, state: dict) -> None:
    state["updatedAt"] = utcnow()
    atomic_write(state_path(state_dir, state["runId"]), state)


def append_history(state: dict, **entry) -> None:
    record = {"at": utcnow()}
    record.update(entry)
    history = state.setdefault("history", [])
    history.append(record)
    if len(history) > HISTORY_LIMIT:
        overflow = len(history) - HISTORY_LIMIT
        # Keep the init entry so the run's origin is never lost.
        del history[1:1 + overflow]
        state["historyTruncated"] = state.get("historyTruncated", 0) + overflow


def failure_signature(result: dict) -> str:
    """Derive a stable signature from observed failures.

    Structured checks and findings always win. A caller-supplied
    ``failureSignature`` is used only when there is nothing structured to hash,
    so a failing agent cannot make each attempt look unique and defeat the
    identical-failure stop.
    """
    failing = []
    for check in result.get("checks", []) or []:
        if isinstance(check, dict) and check.get("ok") is not True:
            failing.append(f"{check.get('name', '?')}:{check.get('message', '')}")
    for finding in result.get("findings", []) or []:
        if isinstance(finding, dict):
            failing.append(f"{finding.get('severity', '?')}:{finding.get('summary', '')}")
    if failing:
        basis = "\n".join(sorted(failing))
    else:
        explicit = result.get("failureSignature")
        if isinstance(explicit, str) and explicit.strip():
            basis = explicit.strip()
        else:
            basis = str(result.get("summary") or result.get("decision") or "unknown-failure")
    return hashlib.sha256(basis.encode("utf-8")).hexdigest()[:16]


def validate_evidence(evidence, repo_root: Path) -> list:
    if not isinstance(evidence, list) or not evidence:
        raise EngineError("result must include at least one evidence pointer")
    pointers = []
    problems = []
    resolved_root = repo_root.resolve()
    for item in evidence:
        if not isinstance(item, str) or not item.strip():
            raise EngineError("evidence entries must be non-empty strings")
        pointer = item.strip()
        normalized = pointer.lower()
        matched_scheme = next(
            (scheme for scheme in EVIDENCE_SCHEMES if normalized.startswith(scheme)), None
        )
        if matched_scheme:
            payload = pointer[len(matched_scheme):].strip()
            if not payload:
                problems.append(f"{pointer!r} has no content after the scheme")
            elif matched_scheme in ("http://", "https://"):
                try:
                    parsed = urlparse(pointer)
                    parsed.port  # raises ValueError on an invalid port
                except ValueError as exc:
                    problems.append(f"{pointer!r} is not a valid URL: {exc}")
                    continue
                if not parsed.netloc:
                    problems.append(f"{pointer!r} has no host after the scheme")
                elif parsed.username is not None or parsed.password is not None:
                    problems.append(f"{pointer!r} must not embed credentials")
                elif parsed.query:
                    problems.append(
                        f"{pointer!r} must not include a query string; "
                        "use the artifact: scheme for signed or tokenized links"
                    )
            pointers.append(pointer)
            continue
        raw = Path(pointer)
        candidate = raw if raw.is_absolute() else repo_root / raw
        try:
            resolved = candidate.resolve()
            exists = resolved.exists()
            is_file = resolved.is_file()
            contained = resolved.is_relative_to(resolved_root)
        except (OSError, ValueError) as exc:
            problems.append(f"{pointer!r} cannot be resolved: {exc}")
            continue
        if not exists:
            problems.append(f"{pointer!r} does not exist")
        elif not is_file:
            problems.append(f"{pointer!r} is not a file")
        elif not contained:
            problems.append(
                f"{pointer!r} is outside the repository root; "
                "use an artifact:, screenshot:, trace:, or benchmark: scheme instead"
            )
        pointers.append(pointer)
    if problems:
        raise EngineError(
            "invalid evidence pointers: " + "; ".join(problems)
        )
    return pointers


def _validate_write_set(write_set, repo_root: Path) -> None:
    if not isinstance(write_set, list):
        raise EngineError("task.writeSet must be a list (may be empty for read-only work)")
    for entry in write_set:
        if not isinstance(entry, str) or not entry.strip():
            raise EngineError("task.writeSet entries must be non-empty strings")
        normalized = entry.strip().lower()
        if normalized in UNBOUNDED_WRITE_SET_ENTRIES or any(char in entry for char in "*?"):
            raise EngineError(
                f"task.writeSet entry {entry!r} is unbounded; declare explicit paths"
            )
        # A write set is the boundary the engine later checks files against, so
        # an entry the boundary cannot express is a hole in the boundary, not a
        # harmless typo. Evidence pointers already reject absolute and outside-
        # root paths; the write set needs the same treatment or a task can
        # declare its way out of the repository.
        stripped = entry.strip()
        # An absolute path has to be refused on every host, not just the one the
        # engine runs on: "C:/x.py" is not absolute to POSIX Path, and "/x.py" is
        # not absolute to Windows Path, but neither is a repository-relative path.
        drive_qualified = bool(re.match(r"^[A-Za-z]:", stripped))
        if stripped.startswith(("/", "\\", "~")) or drive_qualified or Path(stripped).is_absolute():
            raise EngineError(
                f"task.writeSet entry {entry!r} must be a repository-relative path"
            )
        if any(part == ".." for part in Path(stripped).parts):
            raise EngineError(
                f"task.writeSet entry {entry!r} must not traverse outside the repository"
            )
        if stripped.endswith(("/", "\\")) or stripped in {".", "./", ".\\"}:
            raise EngineError(
                f"task.writeSet entry {entry!r} must name a file, not a directory"
            )
        try:
            resolved = (repo_root / stripped).resolve()
        except (OSError, ValueError) as exc:
            raise EngineError(
                f"task.writeSet entry {entry!r} cannot be resolved: {exc}"
            ) from exc
        if not resolved.is_relative_to(repo_root.resolve()):
            raise EngineError(
                f"task.writeSet entry {entry!r} resolves outside the repository root"
            )
        if resolved.is_dir():
            raise EngineError(
                f"task.writeSet entry {entry!r} is a directory; name the files instead"
            )


@contextlib.contextmanager
def run_lock(state_dir: Path, run_id: str):
    """Advisory per-run lock so concurrent records cannot lose updates."""
    try:
        state_dir.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise EngineError(f"state directory cannot be created: {state_dir} ({exc})") from exc
    if not state_dir.is_dir():
        raise EngineError(f"state path is not a directory: {state_dir}")
    lock_path = state_dir / f".{run_id}.lock"
    deadline = time.monotonic() + LOCK_TIMEOUT_SECONDS
    while True:
        try:
            fd = os.open(str(lock_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            try:
                os.write(fd, str(os.getpid()).encode("ascii", "replace"))
            finally:
                os.close(fd)
            break
        except FileExistsError:
            try:
                age = time.time() - lock_path.stat().st_mtime
                if age > LOCK_STALE_SECONDS:
                    lock_path.unlink()
                    continue
            except FileNotFoundError:
                continue
            if time.monotonic() > deadline:
                raise EngineError(f"state is locked by another process: {lock_path.name}")
            time.sleep(0.05)
    try:
        yield
    finally:
        with contextlib.suppress(FileNotFoundError):
            lock_path.unlink()


def minutes_elapsed(state: dict) -> float:
    created = state.get("createdAt")
    if not created:
        return 0.0
    try:
        started = datetime.fromisoformat(created)
    except ValueError:
        return 0.0
    return (datetime.now(timezone.utc) - started).total_seconds() / 60.0


def block(state: dict, reason: str, detail: str, evidence: list) -> None:
    state["stage"] = "blocked"
    state["status"] = "BLOCKED"
    state["blocker"] = {
        "reason": reason,
        "detail": detail,
        "attempts": state.get("repairAttempts", 0),
        "verifyAttempts": state.get("verifyAttempts", 0),
        "evidence": evidence,
        "at": utcnow(),
    }
    append_history(state, stage="blocked", action="escalate", reason=reason, detail=detail)


def validate_task(task: dict, policy: dict, repo_root: Path) -> dict:
    if not isinstance(task, dict):
        raise EngineError("task must be a JSON object")
    for field in ("taskId", "title"):
        if not isinstance(task.get(field), str) or not task[field].strip():
            raise EngineError(f"task.{field} is required")
    criteria = task.get("acceptanceCriteria")
    if not isinstance(criteria, list) or not criteria:
        raise EngineError("task.acceptanceCriteria must be a non-empty list")
    if not all(isinstance(item, str) and item.strip() for item in criteria):
        raise EngineError("task.acceptanceCriteria entries must be non-empty strings")
    _validate_write_set(task.get("writeSet"), repo_root)
    categories = approval_categories(policy)
    category = task.get("approvalCategory")
    if category is not None and category not in categories:
        raise EngineError(f"task.approvalCategory is not a known category: {category}")
    requested_by = task.get("requestedBy")
    if category is not None and (not isinstance(requested_by, str) or not requested_by.strip()):
        raise EngineError("task.requestedBy is required when task.approvalCategory is set")
    task.setdefault("class", "FEATURE")
    task.setdefault("complexity", "simple")
    known_classes = {item.get("id") for item in policy.get("taskClasses", []) if isinstance(item, dict)}
    if known_classes and task["class"] not in known_classes:
        raise EngineError(f"task.class is not a known task class: {task['class']}")
    task.setdefault("evidenceSurfaces", [])
    if not isinstance(task["evidenceSurfaces"], list):
        raise EngineError("task.evidenceSurfaces must be a list")
    # changedFilesFrom decides who is authoritative about what changed. The
    # default keeps the caller's declared list, which is what every existing task
    # and self-test expects. Setting it to "git" makes the repository
    # authoritative, so an under-reported filesChanged cannot satisfy the gate.
    changed_from = task.setdefault("changedFilesFrom", "declared")
    if changed_from not in ("declared", "git"):
        raise EngineError(
            "task.changedFilesFrom must be 'declared' or 'git'; "
            f"found {changed_from!r}"
        )
    known_surfaces = set(
        (policy.get("evidenceRequirements", {}) or {}).get("surfaces", {}) or {}
    )
    unknown = [surface for surface in task["evidenceSurfaces"] if surface not in known_surfaces]
    if known_surfaces and unknown:
        raise EngineError(
            "task.evidenceSurfaces contains unknown surfaces: " + ", ".join(map(str, unknown))
        )
    return task


def next_payload(state: dict) -> dict:
    stage = state["stage"]
    payload = {
        "runId": state["runId"],
        "taskId": state["task"]["taskId"],
        "title": state["task"]["title"],
        "stage": stage,
        "status": state["status"],
        "attempt": state.get("attempt", 0),
        "repairAttempts": state.get("repairAttempts", 0),
        "verifyAttempts": state.get("verifyAttempts", 0),
        "acceptanceCriteria": state["task"]["acceptanceCriteria"],
        "writeSet": state["task"]["writeSet"],
    }
    if stage == "blocked":
        payload["blocker"] = state.get("blocker")
        payload["action"] = "Escalate to the user with the blocker packet. Do not retry."
        return payload
    if stage == "done":
        payload["action"] = "None. The task is complete with verification evidence."
        return payload
    instructions = STAGE_INSTRUCTIONS[stage]
    payload["objective"] = instructions["objective"]
    payload["action"] = instructions["action"]
    payload["requiredResult"] = instructions["requiredResult"]
    if stage == "approval":
        payload["approvalCategory"] = state["task"].get("approvalCategory")
    if stage in ("implement", "repair"):
        payload["blockingFindings"] = state.get("blockingFindings", [])
        payload["implementers"] = state.get("implementers", [])
    if stage == "review":
        payload["implementers"] = state.get("implementers", [])
        payload["note"] = "reviewedBy must not match any implementer"
    return payload


def cmd_init(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    policy = load_policy(repo_root)
    task = validate_task(read_json_file(args.task), policy, repo_root)
    state_dir = state_dir_for(repo_root, args.state_dir)
    path = state_path(state_dir, args.run_id)
    with run_lock(state_dir, args.run_id):
        if path.exists() and not args.force:
            raise EngineError(f"state already exists for run-id {args.run_id}; use --force to replace")
        if path.exists() and args.force:
            previous = read_state_file(path)
            if previous.get("stage") != "implement":
                raise EngineError(
                    f"refusing to replace a run at stage {previous.get('stage')}; "
                    "use a new run-id to preserve the audit trail"
                )
        state = {
            "runId": args.run_id,
            "status": "RUNNING",
            "stage": "approval" if task.get("approvalCategory") else "implement",
            "task": task,
            "attempt": 0,
            "repairAttempts": 0,
            "verifyAttempts": 0,
            "failureSignatures": {},
            "approvals": [],
            "blockingFindings": [],
            "implementers": [],
            "history": [],
            "createdAt": utcnow(),
            "updatedAt": utcnow(),
        }
        append_history(state, stage=state["stage"], action="init", detail="run initialized")
        save_state(state_dir, state)
    emit(next_payload(state))
    return 0


def cmd_next(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    policy = load_policy(repo_root)
    state_dir = state_dir_for(repo_root, args.state_dir)
    with run_lock(state_dir, args.run_id):
        state = load_state(state_dir, args.run_id)
        _check_budget(state, policy)
        if state["stage"] == "blocked":
            save_state(state_dir, state)
    emit(next_payload(state))
    return 3 if state["stage"] == "blocked" else 0


def cmd_status(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    state_dir = state_dir_for(repo_root, args.state_dir)
    state = load_state(state_dir, args.run_id)
    emit(
        {
            "runId": state["runId"],
            "taskId": state["task"]["taskId"],
            "title": state["task"]["title"],
            "status": state["status"],
            "stage": state["stage"],
            "repairAttempts": state.get("repairAttempts", 0),
            "verifyAttempts": state.get("verifyAttempts", 0),
            "failureSignatures": state.get("failureSignatures", {}),
            "approvals": state.get("approvals", []),
            "implementers": state.get("implementers", []),
            "blocker": state.get("blocker"),
            "historyLength": len(state.get("history", [])),
            "historyTruncated": state.get("historyTruncated", 0),
            "createdAt": state.get("createdAt"),
            "updatedAt": state.get("updatedAt"),
        }
    )
    return 3 if state["stage"] == "blocked" else 0


def cmd_report(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    state_dir = state_dir_for(repo_root, args.state_dir)
    state = load_state(state_dir, args.run_id)
    emit(state)
    return 3 if state["stage"] == "blocked" else 0


def _check_budget(state: dict, policy: dict) -> None:
    limits = retry_policy(policy)
    limit = limits.get("maxWallClockMinutes")
    if isinstance(limit, (int, float)) and limit > 0 and minutes_elapsed(state) > limit:
        detail = (
            f"run exceeded the {limit}-minute wall-clock budget "
            f"during stage {state.get('stage', '?')} after {state.get('attempt', 0)} attempt(s); "
            f"last evidence came from stage {state.get('lastEvidenceStage', 'none')}"
        )
        block(state, "wall-clock-budget-exceeded", detail, state.get("lastEvidence", []))


def _normalize_path(value: str) -> str:
    normalized = str(value).strip().replace("\\", "/")
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized.lower() if CASE_INSENSITIVE_PATHS else normalized


def _outside_write_set(files: list, write_set: list) -> list:
    allowed = {_normalize_path(item) for item in write_set}
    return [str(item) for item in files if _normalize_path(str(item)) not in allowed]


def _git_changed_files(repo_root: Path) -> list:
    """Changed paths in the working tree, repo-relative.

    Used when the task sets `changedFilesFrom: git`, so the write-set gate reads
    the repository instead of trusting the caller self-report. Untracked files
    are included because a new file is exactly the case an under-report hides.

    Fails closed: if git cannot answer, the caller gets an error rather than an
    empty set, because an empty set would silently pass every write set.
    """
    try:
        status = subprocess.run(
            [
                "git",
                "-C",
                str(repo_root),
                "status",
                "--porcelain=v1",
                "-z",
                # Without -uall git collapses a fully untracked directory to
                # "dir/", which can never match a write-set entry.
                "--untracked-files=all",
                # Renames emit two NUL-separated paths; --no-renames keeps one.
                "--no-renames",
            ],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise EngineError(
            f"changedFilesFrom is 'git' but git could not be run: {exc}"
        ) from exc
    if status.returncode != 0:
        detail = (status.stderr or "").strip().splitlines()
        raise EngineError(
            "changedFilesFrom is 'git' but the repository could not be read: "
            + (detail[0] if detail else f"exit {status.returncode}")
        )
    changed = []
    for entry in status.stdout.split("\0"):
        if not entry or len(entry) < 4:
            continue
        # porcelain v1 is "XY <path>": two status characters, a space, the path.
        path = entry[3:]
        if path.startswith('"') and path.endswith('"'):
            path = path[1:-1]
        path = path.replace("\\", "/")
        # Generated artifacts are not work. Importing any module in this
        # repository writes __pycache__, and reporting that as an out-of-scope
        # change would block every git-mode run for a file nobody edited.
        if any(marker in path.split("/") for marker in GENERATED_PATH_MARKERS):
            continue
        if path.endswith(GENERATED_SUFFIXES):
            continue
        changed.append(path)
    return sorted(dict.fromkeys(changed))


def _handle_failure(state: dict, policy: dict, result: dict, evidence: list) -> tuple[str, str]:
    limits = retry_policy(policy)
    signature = failure_signature(result)
    signatures = state.setdefault("failureSignatures", {})
    signatures[signature] = signatures.get(signature, 0) + 1
    threshold = limits.get("identicalFailureThreshold", 2)
    if limits.get("escalateOnIdenticalFailure", True) and signatures[signature] >= threshold:
        block(
            state,
            "identical-failure",
            f"the same failure signature repeated {signatures[signature]} time(s)",
            evidence,
        )
        return "blocked", "identical-failure"
    max_attempts = limits.get("maxRepairAttempts", 3)
    if state.get("repairAttempts", 0) >= max_attempts:
        block(
            state,
            "attempt-budget-exhausted",
            f"repair attempts reached {max_attempts}",
            evidence,
        )
        return "blocked", "attempt-budget-exhausted"
    state["repairAttempts"] = state.get("repairAttempts", 0) + 1
    state["attempt"] = state.get("attempt", 0) + 1
    state["stage"] = "repair"
    state["status"] = "RUNNING"
    state["blockingFindings"] = [
        {"signature": signature, "checks": result.get("checks", []), "findings": result.get("findings", [])}
    ]
    return "repair", "repair-scheduled"


def cmd_record(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    policy = load_policy(repo_root)
    limits = retry_policy(policy)
    state_dir = state_dir_for(repo_root, args.state_dir)
    with run_lock(state_dir, args.run_id):
        state = load_state(state_dir, args.run_id)
        return _record_locked(args, repo_root, policy, limits, state_dir, state)


def _record_locked(args, repo_root, policy, limits, state_dir, state) -> int:
    if state["stage"] == "blocked":
        raise EngineError("run is blocked; escalate instead of recording more work")
    if state["stage"] == "done":
        raise EngineError("run is already complete")
    if args.stage != state["stage"]:
        raise EngineError(f"recorded stage {args.stage} does not match current stage {state['stage']}")
    _check_budget(state, policy)
    if state["stage"] == "blocked":
        save_state(state_dir, state)
        emit(next_payload(state))
        return 3
    result = read_json_file(args.result)
    evidence = validate_evidence(result.get("evidence"), repo_root)
    state["lastEvidence"] = evidence
    state["lastEvidenceStage"] = args.stage

    if args.stage in ("implement", "repair"):
        if result.get("status") != "done":
            raise EngineError("implement/repair result must set status to 'done'")
        implemented_by = result.get("implementedBy")
        if not isinstance(implemented_by, str) or not implemented_by.strip():
            raise EngineError("implement/repair result must name implementedBy")
        files = result.get("filesChanged") or []
        if not isinstance(files, list):
            raise EngineError("filesChanged must be a list")
        if not all(isinstance(item, str) and item.strip() for item in files):
            raise EngineError("filesChanged entries must be non-empty strings")
        # When the task makes git authoritative, the declared list is replaced by
        # what the repository says actually changed, and any file the caller
        # claimed but git does not report is dropped. That is what stops an
        # under-report from satisfying the gate.
        declared = [str(item) for item in files]
        if state["task"].get("changedFilesFrom") == "git":
            files = _git_changed_files(repo_root)
            unreported = sorted(
                set(_normalize_path(item) for item in declared)
                - set(_normalize_path(item) for item in files)
            )
            if unreported:
                append_history(
                    state,
                    stage=args.stage,
                    action="note",
                    detail="declared files not reported by git were ignored: "
                    + ", ".join(unreported),
                )
        outside = _outside_write_set(files, state["task"]["writeSet"])
        if outside:
            block(
                state,
                "write-set-violation",
                "changed files outside the declared write set: " + ", ".join(outside),
                evidence,
            )
            save_state(state_dir, state)
            emit(next_payload(state))
            return 3
        implementers = state.setdefault("implementers", [])
        if implemented_by.strip() not in implementers:
            implementers.append(implemented_by.strip())
        state["lastStage"] = args.stage
        state["stage"] = "verify"
        state["status"] = "RUNNING"
        append_history(
            state,
            stage=args.stage,
            action="recorded",
            implementedBy=implemented_by.strip(),
            files=files,
            evidence=evidence,
        )

    elif args.stage == "verify":
        verdict = result.get("result")
        if verdict not in ("VERIFIED", "NOT_VERIFIED", "INCONCLUSIVE"):
            raise EngineError("verify result must be VERIFIED, NOT_VERIFIED, or INCONCLUSIVE")
        checks = result.get("checks")
        if not isinstance(checks, list) or not checks:
            raise EngineError("verify result must include at least one check")
        if not all(isinstance(check, dict) and isinstance(check.get("name"), str) and check["name"].strip() for check in checks):
            raise EngineError("every check must have a non-empty name")
        failing = [check for check in checks if check.get("ok") is not True]
        if verdict == "VERIFIED" and failing:
            raise EngineError(
                "VERIFIED is refused while checks report failures: "
                + ", ".join(str(check.get("name")) for check in failing)
            )
        append_history(state, stage="verify", action="recorded", result=verdict, evidence=evidence)
        state["lastStage"] = "verify"
        if verdict == "VERIFIED":
            state["stage"] = "review"
            state["status"] = "RUNNING"
            state["verifyAttempts"] = 0
        elif verdict == "NOT_VERIFIED":
            _handle_failure(state, policy, result, evidence)
        else:
            retries = state.get("verifyAttempts", 0) + 1
            max_retries = limits.get("maxVerifyRetries", 1)
            if limits.get("inconclusiveIsNeverSuccess", True) and retries > max_retries:
                block(
                    state,
                    "inconclusive",
                    "verification stayed INCONCLUSIVE after the allowed retries",
                    evidence,
                )
            else:
                state["verifyAttempts"] = retries
                append_history(
                    state,
                    stage="verify",
                    action="retry",
                    detail=f"INCONCLUSIVE retry {retries}/{max_retries}",
                )

    elif args.stage == "review":
        decision = result.get("decision")
        if decision not in ("pass", "needs-revision"):
            raise EngineError("review decision must be 'pass' or 'needs-revision'")
        reviewed_by = result.get("reviewedBy")
        if not isinstance(reviewed_by, str) or not reviewed_by.strip():
            raise EngineError("review result must name reviewedBy")
        implementers = {item.lower() for item in state.get("implementers", [])}
        if reviewed_by.strip().lower() in implementers:
            raise EngineError("a reviewer cannot approve work it implemented itself")
        findings = result.get("findings")
        if not isinstance(findings, list):
            raise EngineError("review result must include a findings list")
        if decision == "needs-revision" and not findings:
            raise EngineError("a needs-revision review must name at least one finding")
        append_history(
            state,
            stage="review",
            action="recorded",
            decision=decision,
            reviewedBy=reviewed_by.strip(),
            evidence=evidence,
        )
        # lastStage is what a reader of `report` uses to see which stage ran last.
        # Leaving it at "verify" on a completed run says review never happened,
        # which is the one stage that authorises completion.
        state["lastStage"] = "review"
        if decision == "pass":
            state["stage"] = "done"
            state["status"] = "DONE"
            state["completedAt"] = utcnow()
        else:
            _handle_failure(state, policy, result, evidence)

    else:
        raise EngineError(f"stage {args.stage} cannot be recorded")

    save_state(state_dir, state)
    emit(next_payload(state))
    return 3 if state["stage"] == "blocked" else 0


def cmd_approve(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    policy = load_policy(repo_root)
    state_dir = state_dir_for(repo_root, args.state_dir)
    with run_lock(state_dir, args.run_id):
        state = load_state(state_dir, args.run_id)
        _check_budget(state, policy)
        if state["stage"] == "blocked":
            save_state(state_dir, state)
            emit(next_payload(state))
            return 3
        if state["stage"] != "approval":
            raise EngineError("run is not waiting for approval")
        approver = args.approver.strip()
        if not approver:
            raise EngineError("approver is required")
        requested_by = str(state["task"].get("requestedBy") or "").strip()
        if requested_by and approver.lower() == requested_by.lower():
            raise EngineError("the requester cannot approve their own high-risk change")
        state.setdefault("approvals", []).append(
            {
                "category": state["task"].get("approvalCategory"),
                "approver": approver,
                "requestedBy": requested_by or None,
                "note": (args.note or "").strip(),
                "at": utcnow(),
            }
        )
        state["stage"] = "implement"
        state["status"] = "RUNNING"
        append_history(state, stage="approval", action="recorded", approver=approver)
        save_state(state_dir, state)
    emit(next_payload(state))
    return 0


TOOL_REGISTRY_PATH = Path(".github") / "roles" / "tool-access.json"

# A done or blocked run bounds nothing, so only these stages restrict tools.
ACTIVE_STAGES = ("approval", "implement", "verify", "repair", "review")

# Only `edit` changes working-tree files, so only `edit` is checked against the
# write set. The other kinds cannot widen the change.
WRITE_KINDS = frozenset({"edit"})

# Writes and delegation are what a stage actually gates. Reading, searching, and
# todo tracking stay available everywhere because they cannot widen the change.
STAGE_TOOL_PROFILES = {
    "approval": {"read": True, "search": True, "execute": False, "edit": False, "todo": True, "delegate-agent": False},
    "implement": {"read": True, "search": True, "execute": True, "edit": True, "todo": True, "delegate-agent": False},
    "verify": {"read": True, "search": True, "execute": True, "edit": False, "todo": True, "delegate-agent": False},
    "repair": {"read": True, "search": True, "execute": True, "edit": True, "todo": True, "delegate-agent": False},
    "review": {"read": True, "search": True, "execute": True, "edit": False, "todo": True, "delegate-agent": False},
}

# Host argument shapes for file targets. A write that names no path is denied
# rather than assumed safe, because "no path" is exactly what an escape looks like.
WRITE_PATH_KEYS = ("filePath", "path", "file", "targetFile", "dirPath")
WRITE_PATH_LIST_KEYS = ("files", "paths", "edits")


def load_tool_kinds(repo_root: Path) -> dict:
    """Map concrete host tool name to capability kind.

    The role registry is the single source of truth for the vocabulary, so this
    gate cannot drift from the matrix the supervisor validator already reads.
    """
    registry_path = repo_root / TOOL_REGISTRY_PATH
    if not registry_path.is_file():
        raise EngineError(f"missing tool registry: {TOOL_REGISTRY_PATH.as_posix()}")
    definitions = read_json_file(str(registry_path)).get("toolDefinitions")
    if not isinstance(definitions, dict):
        raise EngineError("tool registry is missing toolDefinitions")
    kinds = {}
    for kind, definition in definitions.items():
        examples = definition.get("examples") if isinstance(definition, dict) else None
        if not isinstance(examples, list):
            continue
        for name in examples:
            # delegate-agent documents a platform mapping, not a literal name.
            if isinstance(name, str) and name and " " not in name:
                kinds[name] = kind
    return kinds


def active_runs(state_dir: Path) -> list:
    """Runs whose stage still bounds an agent."""
    if not state_dir.is_dir():
        return []
    runs = []
    for path in sorted(state_dir.glob("*.json")):
        # atomic_write stages through .tmp-*.json; a half-written file is not a run.
        if path.name.startswith(".tmp-"):
            continue
        state = validate_state(read_state_file(path), path.stem)
        if state["stage"] in ACTIVE_STAGES:
            runs.append(state)
    return runs


def write_paths(tool_args: dict) -> list:
    found = []
    for key in WRITE_PATH_KEYS:
        value = tool_args.get(key)
        if isinstance(value, str) and value.strip():
            found.append(value.strip())
    for key in WRITE_PATH_LIST_KEYS:
        value = tool_args.get(key)
        if not isinstance(value, list):
            continue
        for item in value:
            if isinstance(item, str) and item.strip():
                found.append(item.strip())
            elif isinstance(item, dict):
                for inner in WRITE_PATH_KEYS:
                    nested = item.get(inner)
                    if isinstance(nested, str) and nested.strip():
                        found.append(nested.strip())
    return found


def check_tool_call(repo_root: Path, state_dir: Path, payload: dict) -> tuple:
    """Decide a preToolUse payload. Returns (allowed, reason).

    With no active run the answer is always yes: ordinary editing is unbounded,
    and inventing a bound nobody declared would break every normal session.
    """
    if not isinstance(payload, dict):
        return False, "hook payload must be a JSON object"

    runs = active_runs(state_dir)
    if not runs:
        return True, ""

    tool_name = payload.get("toolName")
    if not isinstance(tool_name, str) or not tool_name:
        return False, "hook payload has no toolName"

    kind = load_tool_kinds(repo_root).get(tool_name)
    if kind is None:
        return False, (
            f"tool {tool_name!r} is not classified in {TOOL_REGISTRY_PATH.as_posix()}; "
            "classify it before running an agent under the engine"
        )

    tool_args = payload.get("toolArgs")
    if tool_args is None:
        tool_args = {}
    if not isinstance(tool_args, dict):
        return False, "toolArgs must be a JSON object"

    for state in runs:
        profile = STAGE_TOOL_PROFILES[state["stage"]]
        if not profile.get(kind, False):
            return False, (
                f"{tool_name!r} is a {kind} call and run {state['runId']} is at stage "
                f"{state['stage']!r}, which does not permit {kind}"
            )
        if kind in WRITE_KINDS:
            paths = write_paths(tool_args)
            if not paths:
                return False, f"{tool_name!r} is a write call but reported no file path"
            allowed = {_normalize_path(item) for item in state["task"]["writeSet"]}
            outside = sorted({path for path in paths if _normalize_path(path) not in allowed})
            if outside:
                return False, (
                    f"write outside the declared write set for run {state['runId']}: "
                    + ", ".join(outside)
                )
    return True, ""


def cmd_check_tool(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    state_dir = state_dir_for(repo_root, args.state_dir)
    raw = sys.stdin.read().strip()
    if not raw:
        return 0
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        emit({"permissionDecision": "deny", "permissionDecisionReason": f"hook payload is not valid JSON: {exc}"})
        return 2
    try:
        allowed, reason = check_tool_call(repo_root, state_dir, payload)
    except EngineError as exc:
        allowed, reason = False, str(exc)
    if allowed:
        return 0
    emit({"permissionDecision": "deny", "permissionDecisionReason": reason})
    return 2


class EngineSelfTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="agentic-engine-test-"))
        (self.root / ".github" / "roles").mkdir(parents=True)
        policy = {
            "retryPolicy": {
                "maxRepairAttempts": 3,
                "identicalFailureThreshold": 2,
                "maxVerifyRetries": 1,
                "inconclusiveIsNeverSuccess": True,
            },
            "approvalRequiredCategories": [{"id": "identity-security-change", "description": "fixture"}],
            "taskClasses": [
                {"id": "FEATURE", "description": "fixture"},
                {"id": "DOCUMENTATION", "description": "fixture"},
            ],
            "evidenceRequirements": {
                "surfaces": {"api": {"evidence": ["fixture"]}, "ui": {"evidence": ["fixture"]}}
            },
        }
        (self.root / ".github" / "roles" / "orchestration-policy.json").write_text(
            json.dumps(policy), encoding="utf-8"
        )
        self.state_dir = self.root / ".agentic" / "state"
        self.task_path = self.root / "task.json"
        self.write_task()

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def write_task(self, **overrides) -> None:
        task = {
            "taskId": "T-1",
            "title": "fixture",
            "acceptanceCriteria": ["it works"],
            "writeSet": ["src/a.py"],
            "approvalCategory": None,
        }
        task.update(overrides)
        self.task_path.write_text(json.dumps(task), encoding="utf-8")

    def write_tool_registry(self) -> None:
        definitions = {
            "read": {"examples": ["read_file"]},
            "search": {"examples": ["grep_search"]},
            "edit": {"examples": ["create_file", "replace_string_in_file"]},
            "execute": {"examples": ["run_in_terminal"]},
            "todo": {"examples": ["manage_todo_list"]},
            "delegate-agent": {"examples": ["platform-mapped, not a literal tool name"]},
        }
        (self.root / ".github" / "roles" / "tool-access.json").write_text(
            json.dumps({"toolDefinitions": definitions}), encoding="utf-8"
        )

    def check(self, tool_name: str, tool_args: dict) -> tuple:
        return check_tool_call(
            self.root, self.state_dir, {"toolName": tool_name, "toolArgs": tool_args}
        )

    def test_check_tool_allows_everything_when_no_run_exists(self) -> None:
        self.write_tool_registry()
        allowed, reason = self.check("mystery_tool", {})
        self.assertTrue(allowed, reason)

    def test_check_tool_allows_write_inside_the_write_set(self) -> None:
        self.write_tool_registry()
        self.init()
        allowed, reason = self.check("replace_string_in_file", {"filePath": "./src/a.py"})
        self.assertTrue(allowed, reason)

    def test_check_tool_denies_write_outside_the_write_set(self) -> None:
        self.write_tool_registry()
        self.init()
        allowed, reason = self.check("create_file", {"filePath": "src/b.py"})
        self.assertFalse(allowed)
        self.assertIn("outside the declared write set", reason)

    def test_check_tool_denies_write_at_verify(self) -> None:
        self.write_tool_registry()
        self.init()
        self.implement()
        allowed, reason = self.check("create_file", {"filePath": "src/a.py"})
        self.assertFalse(allowed)
        self.assertIn("does not permit edit", reason)

    def test_check_tool_allows_execute_at_verify(self) -> None:
        self.write_tool_registry()
        self.init()
        self.implement()
        allowed, reason = self.check("run_in_terminal", {"command": "pytest"})
        self.assertTrue(allowed, reason)

    def test_check_tool_denies_unclassified_tool_during_a_run(self) -> None:
        self.write_tool_registry()
        self.init()
        allowed, reason = self.check("mystery_tool", {})
        self.assertFalse(allowed)
        self.assertIn("not classified", reason)

    def test_check_tool_denies_write_without_a_path(self) -> None:
        self.write_tool_registry()
        self.init()
        allowed, reason = self.check("create_file", {"contents": "x"})
        self.assertFalse(allowed)
        self.assertIn("reported no file path", reason)

    def test_check_tool_ignores_finished_runs(self) -> None:
        self.write_tool_registry()
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        self.record(
            "review",
            {"decision": "pass", "reviewedBy": "reviewer", "findings": [], "evidence": ["cmd:review"]},
        )
        allowed, reason = self.check("create_file", {"filePath": "src/z.py"})
        self.assertTrue(allowed, reason)

    def run_cli(self, argv: list) -> tuple[int, dict]:
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer):
            code = main(argv + ["--repo-root", str(self.root), "--state-dir", str(self.state_dir)])
        text = buffer.getvalue().strip()
        return code, (json.loads(text) if text else {})

    def record(self, stage: str, payload: dict) -> tuple[int, dict]:
        result_path = self.root / f"result-{stage}.json"
        result_path.write_text(json.dumps(payload), encoding="utf-8")
        return self.run_cli(["record", "--run-id", "r1", "--stage", stage, "--result", str(result_path)])

    def init(self) -> tuple[int, dict]:
        return self.run_cli(["init", "--run-id", "r1", "--task", str(self.task_path)])

    def raw(self, stage: str, payload: dict) -> tuple[int, dict]:
        return self.record(stage, payload)

    def implement(self) -> tuple[int, dict]:
        return self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/a.py"],
                "evidence": ["diff:HEAD"],
            },
        )

    def verify(self, result: str, checks: list) -> tuple[int, dict]:
        return self.record(
            "verify", {"result": result, "checks": checks, "evidence": ["cmd:pytest"]}
        )

    def test_happy_path(self) -> None:
        self.init()
        self.assertEqual(self.implement()[1]["stage"], "verify")
        self.assertEqual(self.verify("VERIFIED", [{"name": "pytest", "ok": True}])[1]["stage"], "review")
        code, payload = self.record(
            "review",
            {
                "decision": "pass",
                "reviewedBy": "reviewer",
                "findings": [],
                "evidence": ["cmd:review"],
            },
        )
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "done")

    def test_repair_then_success(self) -> None:
        self.init()
        self.implement()
        code, payload = self.verify("NOT_VERIFIED", [{"name": "pytest", "ok": False, "message": "boom"}])
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "repair")
        self.assertEqual(payload["repairAttempts"], 1)
        self.assertEqual(
            self.record(
                "repair",
                {
                    "status": "done",
                    "implementedBy": "engineer",
                    "filesChanged": ["src/a.py"],
                    "evidence": ["diff:HEAD"],
                },
            )[1]["stage"],
            "verify",
        )
        self.assertEqual(self.verify("VERIFIED", [{"name": "pytest", "ok": True}])[1]["stage"], "review")

    def test_identical_failure_escalates(self) -> None:
        self.init()
        self.implement()
        self.verify("NOT_VERIFIED", [{"name": "pytest", "ok": False, "message": "same"}])
        self.record(
            "repair",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/a.py"],
                "evidence": ["diff:HEAD"],
            },
        )
        code, payload = self.verify("NOT_VERIFIED", [{"name": "pytest", "ok": False, "message": "same"}])
        self.assertEqual(code, 3)
        self.assertEqual(payload["stage"], "blocked")
        self.assertEqual(payload["blocker"]["reason"], "identical-failure")

    def test_supplied_signature_cannot_defeat_repeat_guard(self) -> None:
        self.init()
        self.implement()
        self.verify(
            "NOT_VERIFIED",
            [{"name": "pytest", "ok": False, "message": "same"}],
        )
        self.record(
            "repair",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/a.py"],
                "evidence": ["diff:HEAD"],
            },
        )
        result_path = self.root / "spoof.json"
        result_path.write_text(
            json.dumps(
                {
                    "result": "NOT_VERIFIED",
                    "failureSignature": "brand-new-every-time",
                    "checks": [{"name": "pytest", "ok": False, "message": "same"}],
                    "evidence": ["cmd:pytest"],
                }
            ),
            encoding="utf-8",
        )
        code, payload = self.run_cli(
            ["record", "--run-id", "r1", "--stage", "verify", "--result", str(result_path)]
        )
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "identical-failure")

    def test_attempt_budget_escalates(self) -> None:
        self.init()
        self.implement()
        for index in range(3):
            self.verify("NOT_VERIFIED", [{"name": f"check-{index}", "ok": False, "message": str(index)}])
            self.record(
                "repair",
                {
                    "status": "done",
                    "implementedBy": "engineer",
                    "filesChanged": ["src/a.py"],
                    "evidence": ["diff:HEAD"],
                },
            )
        code, payload = self.verify("NOT_VERIFIED", [{"name": "check-final", "ok": False, "message": "final"}])
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "attempt-budget-exhausted")

    def test_inconclusive_never_completes(self) -> None:
        self.init()
        self.implement()
        self.assertEqual(self.verify("INCONCLUSIVE", [{"name": "probe", "ok": True}])[1]["stage"], "verify")
        code, payload = self.verify("INCONCLUSIVE", [{"name": "probe", "ok": True}])
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "inconclusive")

    def test_approval_gate(self) -> None:
        self.write_task(
            approvalCategory="identity-security-change", requestedBy="supervisor"
        )
        self.assertEqual(self.init()[1]["stage"], "approval")
        code, payload = self.run_cli(["approve", "--run-id", "r1", "--approver", "alice", "--note", "ok"])
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "implement")

    def test_self_approval_rejected(self) -> None:
        self.write_task(
            approvalCategory="identity-security-change", requestedBy="supervisor"
        )
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "approve",
                    "--run-id",
                    "r1",
                    "--approver",
                    "supervisor",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)
        self.assertEqual(self.run_cli(["status", "--run-id", "r1"])[1]["stage"], "approval")

    def test_approval_requires_requester(self) -> None:
        self.write_task(approvalCategory="identity-security-change")
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_write_set_violation_blocks(self) -> None:
        self.init()
        code, payload = self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/other.py"],
                "evidence": ["diff:HEAD"],
            },
        )
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "write-set-violation")

    def test_write_set_violation_with_normalized_path_passes(self) -> None:
        self.init()
        code, _ = self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["./src/a.py"],
                "evidence": ["diff:HEAD"],
            },
        )
        self.assertEqual(code, 0)

    def test_wildcard_write_set_rejected(self) -> None:
        self.write_task(writeSet=["*"])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_unbounded_write_set_rejected(self) -> None:
        self.write_task(writeSet=["unknown"])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def _init_with_write_set(self, entry: str) -> int:
        self.write_task(writeSet=[entry])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )

    def test_absolute_write_set_entry_rejected(self) -> None:
        for entry in ("/etc/passwd", "C:/Windows/evil.py", "C:\\Windows\\evil.py", "~/evil.py", "\\\\server\\share\\x.py"):
            with self.subTest(entry=entry):
                self.assertEqual(self._init_with_write_set(entry), 1)

    def test_traversing_write_set_entry_rejected(self) -> None:
        for entry in ("../outside.py", "src/../../outside.py", "a/../../b.py"):
            with self.subTest(entry=entry):
                self.assertEqual(self._init_with_write_set(entry), 1)

    def test_directory_write_set_entry_rejected(self) -> None:
        for entry in ("src/", "src\\", ".", "./"):
            with self.subTest(entry=entry):
                self.assertEqual(self._init_with_write_set(entry), 1)

    def test_existing_directory_name_rejected(self) -> None:
        (self.root / "realdir").mkdir(parents=True, exist_ok=True)
        self.assertEqual(self._init_with_write_set("realdir"), 1)

    def test_nonexistent_bare_name_accepted(self) -> None:
        self.assertEqual(self._init_with_write_set("notyet.py"), 0)

    def test_relative_file_write_set_entry_accepted(self) -> None:
        self.assertEqual(self._init_with_write_set("src/a.py"), 0)

    # --- changedFilesFrom: git ------------------------------------------------
    # These cover the promise ADR 0008 depends on: when git is authoritative, a
    # caller that under-reports what it changed cannot satisfy the write set.

    def _git(self, *args: str) -> None:
        subprocess.run(
            ["git", "-C", str(self.root), *args],
            check=True,
            capture_output=True,
            text=True,
        )

    def _init_git_repository(self) -> None:
        self._git("init", "-q")
        self._git("config", "user.email", "engine-test@example.invalid")
        self._git("config", "user.name", "engine test")
        # Keep the fixture scaffolding out of the changed set so only the files a
        # test creates are reported.
        (self.root / ".gitignore").write_text(
            ".agentic/\ntask.json\nresult-*.json\n", encoding="utf-8"
        )
        self._git("add", "-A")
        self._git("commit", "-qm", "fixture baseline")

    def _record_implement_with(self, declared: list) -> tuple[int, dict]:
        self.init()
        return self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": declared,
                "evidence": ["diff:HEAD"],
            },
        )

    def test_git_mode_rejects_under_reported_change(self) -> None:
        self._init_git_repository()
        self.write_task(writeSet=["src/a.py"], changedFilesFrom="git")
        (self.root / "src").mkdir(parents=True, exist_ok=True)
        (self.root / "src" / "b.py").write_text("x = 1\n", encoding="utf-8")
        # The caller claims the only file it touched is the one it was allowed.
        code, payload = self._record_implement_with(["src/a.py"])
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "write-set-violation")
        self.assertIn("src/b.py", payload["blocker"]["detail"])

    def test_git_mode_ignores_declared_files_git_does_not_report(self) -> None:
        self._init_git_repository()
        self.write_task(writeSet=["src/a.py"], changedFilesFrom="git")
        code, payload = self._record_implement_with(["src/a.py"])
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "verify")
        state = json.loads((self.state_dir / "r1.json").read_text(encoding="utf-8"))
        recorded = [entry for entry in state["history"] if entry.get("action") == "recorded"]
        self.assertEqual(recorded[-1]["files"], [])

    def test_git_mode_accepts_when_repository_agrees(self) -> None:
        self._init_git_repository()
        self.write_task(writeSet=["src/a.py"], changedFilesFrom="git")
        (self.root / "src").mkdir(parents=True, exist_ok=True)
        (self.root / "src" / "a.py").write_text("x = 1\n", encoding="utf-8")
        code, payload = self._record_implement_with(["src/a.py"])
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "verify")

    def test_git_mode_fails_closed_outside_a_repository(self) -> None:
        self.write_task(writeSet=["src/a.py"], changedFilesFrom="git")
        code, _ = self._record_implement_with(["src/a.py"])
        self.assertEqual(code, 1)

    def test_declared_mode_still_trusts_the_caller(self) -> None:
        self.write_task(writeSet=["src/a.py"])
        code, payload = self._record_implement_with(["src/a.py"])
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "verify")

    def test_git_mode_ignores_generated_artifacts(self) -> None:
        # Importing any module in this repository writes __pycache__. Reporting
        # that as an out-of-scope change would block every git-mode run.
        self._init_git_repository()
        self.write_task(writeSet=["src/a.py"], changedFilesFrom="git")
        (self.root / "src").mkdir(parents=True, exist_ok=True)
        (self.root / "src" / "a.py").write_text("x = 1\n", encoding="utf-8")
        cache = self.root / ".github" / "scripts" / "__pycache__"
        cache.mkdir(parents=True, exist_ok=True)
        (cache / "thing.cpython-312.pyc").write_bytes(b"\x00")
        code, payload = self._record_implement_with(["src/a.py"])
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "verify")

    def test_unknown_changed_files_from_rejected(self) -> None:
        self.write_task(writeSet=["src/a.py"], changedFilesFrom="svn")
        code, _ = self.init()
        self.assertEqual(code, 1)

    def test_verify_requires_evidence(self) -> None:
        self.init()
        self.implement()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "verify",
                    "--result",
                    str(self.write_result({"result": "VERIFIED", "checks": [{"name": "p", "ok": True}], "evidence": []})),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)
        self.assertEqual(self.run_cli(["status", "--run-id", "r1"])[1]["stage"], "verify")

    def test_verify_refuses_failing_checks(self) -> None:
        self.init()
        self.implement()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "verify",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "result": "VERIFIED",
                                "checks": [{"name": "pytest", "ok": False, "message": "boom"}],
                                "evidence": ["cmd:pytest"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)
        self.assertEqual(self.run_cli(["status", "--run-id", "r1"])[1]["stage"], "verify")

    def test_verify_requires_a_check(self) -> None:
        self.init()
        self.implement()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "verify",
                    "--result",
                    str(self.write_result({"result": "VERIFIED", "checks": [], "evidence": ["cmd:x"]})),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_review_requires_evidence(self) -> None:
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "review",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "decision": "pass",
                                "reviewedBy": "reviewer",
                                "findings": [],
                                "evidence": [],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_needs_revision_requires_findings(self) -> None:
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "review",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "decision": "needs-revision",
                                "reviewedBy": "reviewer",
                                "findings": [],
                                "evidence": ["cmd:r"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_bogus_evidence_pointer_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["/nonexistent/proof.log"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_missing_evidence_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": [],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)
        self.assertEqual(self.run_cli(["status", "--run-id", "r1"])[1]["stage"], "implement")

    def test_wall_clock_budget_blocks(self) -> None:
        self.write_task()
        policy_path = self.root / ".github" / "roles" / "orchestration-policy.json"
        policy = json.loads(policy_path.read_text(encoding="utf-8"))
        policy["retryPolicy"]["maxWallClockMinutes"] = 0.000001
        policy_path.write_text(json.dumps(policy), encoding="utf-8")
        self.init()
        time.sleep(0.05)
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["diff:HEAD"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 3)
        payload = self.run_cli(["status", "--run-id", "r1"])[1]
        self.assertEqual(payload["stage"], "blocked")
        self.assertEqual(payload["blocker"]["reason"], "wall-clock-budget-exceeded")

    def test_force_cannot_replace_completed_run(self) -> None:
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        self.record(
            "review",
            {
                "decision": "pass",
                "reviewedBy": "reviewer",
                "findings": [],
                "evidence": ["cmd:review"],
            },
        )
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--force",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_case_variant_path_blocked_on_case_sensitive_system(self) -> None:
        module = sys.modules[__name__]
        original = module.CASE_INSENSITIVE_PATHS
        module.CASE_INSENSITIVE_PATHS = False
        try:
            self.init()
            code, payload = self.record(
                "implement",
                {
                    "status": "done",
                    "implementedBy": "engineer",
                    "filesChanged": ["SRC/A.PY"],
                    "evidence": ["diff:HEAD"],
                },
            )
            self.assertEqual(code, 3)
            self.assertEqual(payload["blocker"]["reason"], "write-set-violation")
        finally:
            module.CASE_INSENSITIVE_PATHS = original

    def test_empty_evidence_scheme_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["cmd:"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_directory_evidence_rejected(self) -> None:
        self.init()
        (self.root / "artifacts").mkdir()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["artifacts"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_traversal_evidence_rejected(self) -> None:
        self.init()
        outside = self.root.parent / "outside-proof.log"
        outside.write_text("proof", encoding="utf-8")
        try:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                code = main(
                    [
                        "record",
                        "--run-id",
                        "r1",
                        "--stage",
                        "implement",
                        "--result",
                        str(
                            self.write_result(
                                {
                                    "status": "done",
                                    "implementedBy": "engineer",
                                    "filesChanged": ["src/a.py"],
                                    "evidence": [f"../{outside.name}"],
                                }
                            )
                        ),
                        "--repo-root",
                        str(self.root),
                        "--state-dir",
                        str(self.state_dir),
                    ]
                )
            self.assertEqual(code, 1)
        finally:
            outside.unlink()

    def test_self_review_rejected(self) -> None:
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "review",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "decision": "pass",
                                "reviewedBy": "engineer",
                                "findings": [],
                                "evidence": ["cmd:review"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_review_requires_reviewer(self) -> None:
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "review",
                    "--result",
                    str(
                        self.write_result(
                            {"decision": "pass", "findings": [], "evidence": ["cmd:review"]}
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_force_cannot_replace_blocked_run(self) -> None:
        self.init()
        self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/other.py"],
                "evidence": ["diff:HEAD"],
            },
        )
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--force",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_report_exit_code_matches_blocked_state(self) -> None:
        self.init()
        self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/other.py"],
                "evidence": ["diff:HEAD"],
            },
        )
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer):
            code = main(
                [
                    "report",
                    "--run-id",
                    "r1",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 3)

    def test_unknown_task_class_rejected(self) -> None:
        self.write_task(**{"class": "NOT_A_CLASS"})
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_unknown_evidence_surface_rejected(self) -> None:
        self.write_task(evidenceSurfaces=["network"])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_history_is_capped(self) -> None:
        state = {"history": []}
        for index in range(HISTORY_LIMIT + 25):
            append_history(state, index=index)
        self.assertEqual(len(state["history"]), HISTORY_LIMIT)
        self.assertEqual(state["historyTruncated"], 25)

    def test_sibling_prefix_traversal_rejected(self) -> None:
        sibling = self.root.parent / (self.root.name + "evil")
        sibling.mkdir()
        (sibling / "proof.log").write_text("proof", encoding="utf-8")
        try:
            self.init()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                code = main(
                    [
                        "record",
                        "--run-id",
                        "r1",
                        "--stage",
                        "implement",
                        "--result",
                        str(
                            self.write_result(
                                {
                                    "status": "done",
                                    "implementedBy": "engineer",
                                    "filesChanged": ["src/a.py"],
                                    "evidence": [f"../{sibling.name}/proof.log"],
                                }
                            )
                        ),
                        "--repo-root",
                        str(self.root),
                        "--state-dir",
                        str(self.state_dir),
                    ]
                )
            self.assertEqual(code, 1)
        finally:
            shutil.rmtree(sibling, ignore_errors=True)

    def test_absolute_evidence_outside_repo_rejected(self) -> None:
        outside = self.root.parent / "outside-absolute-proof.log"
        outside.write_text("proof", encoding="utf-8")
        try:
            self.init()
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                code = main(
                    [
                        "record",
                        "--run-id",
                        "r1",
                        "--stage",
                        "implement",
                        "--result",
                        str(
                            self.write_result(
                                {
                                    "status": "done",
                                    "implementedBy": "engineer",
                                    "filesChanged": ["src/a.py"],
                                    "evidence": [str(outside)],
                                }
                            )
                        ),
                        "--repo-root",
                        str(self.root),
                        "--state-dir",
                        str(self.state_dir),
                    ]
                )
            self.assertEqual(code, 1)
        finally:
            outside.unlink()

    def test_absolute_evidence_inside_repo_accepted(self) -> None:
        (self.root / "proof.log").write_text("proof", encoding="utf-8")
        self.init()
        code, _ = self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/a.py"],
                "evidence": [str(self.root / "proof.log")],
            },
        )
        self.assertEqual(code, 0)

    def test_url_without_path_accepted(self) -> None:
        self.init()
        code, _ = self.record(
            "implement",
            {
                "status": "done",
                "implementedBy": "engineer",
                "filesChanged": ["src/a.py"],
                "evidence": ["http://example.com"],
            },
        )
        self.assertEqual(code, 0)

    def test_hostless_url_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["http:///"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_review_stage_surfaces_implementers(self) -> None:
        self.init()
        self.implement()
        _, payload = self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        self.assertEqual(payload["stage"], "review")
        self.assertEqual(payload["implementers"], ["engineer"])

    def test_last_stage_records_review_on_completion(self) -> None:
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        review = {
            "decision": "pass",
            "reviewedBy": "reviewer",
            "findings": [],
            "evidence": ["diff:HEAD"],
        }
        self.review_file = self.root / "review.json"
        self.review_file.write_text(json.dumps(review), encoding="utf-8")
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "review",
                    "--result",
                    str(self.review_file),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 0)
        state = json.loads((self.state_dir / "r1.json").read_text(encoding="utf-8"))
        self.assertEqual(state["status"], "DONE")
        self.assertEqual(state["lastStage"], "review")

    def test_force_refused_at_review_stage(self) -> None:
        self.init()
        self.implement()
        self.verify("VERIFIED", [{"name": "pytest", "ok": True}])
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--force",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_malformed_url_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["http://[::1"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_url_credentials_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["http://user:pass@example.com"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_nul_path_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["bad\x00path.log"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_corrupt_state_reports_error(self) -> None:
        self.init()
        state_file = self.state_dir / "r1.json"
        state_file.write_text("not json", encoding="utf-8")
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer), contextlib.redirect_stderr(buffer):
            code = main(
                [
                    "status",
                    "--run-id",
                    "r1",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)
        self.assertIn("[ERROR]", buffer.getvalue())

    def test_state_dir_as_file_reports_error(self) -> None:
        blocker = self.root / "state-file"
        blocker.write_text("x", encoding="utf-8")
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer), contextlib.redirect_stderr(buffer):
            code = main(
                [
                    "init",
                    "--run-id",
                    "r1",
                    "--task",
                    str(self.task_path),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(blocker),
                ]
            )
        self.assertEqual(code, 1)
        self.assertIn("[ERROR]", buffer.getvalue())

    def test_missing_state_field_reports_error(self) -> None:
        self.init()
        state_file = self.state_dir / "r1.json"
        state_file.write_text("{}", encoding="utf-8")
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer), contextlib.redirect_stderr(buffer):
            code = main(
                [
                    "status",
                    "--run-id",
                    "r1",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)
        self.assertIn("[ERROR]", buffer.getvalue())
        self.assertNotIn("Traceback", buffer.getvalue())

    def test_unknown_state_stage_reports_error(self) -> None:
        self.init()
        state_file = self.state_dir / "r1.json"
        state = json.loads(state_file.read_text(encoding="utf-8"))
        state["stage"] = "nonsense"
        state_file.write_text(json.dumps(state), encoding="utf-8")
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer), contextlib.redirect_stderr(buffer):
            code = main(
                [
                    "next",
                    "--run-id",
                    "r1",
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)
        self.assertIn("unknown stage", buffer.getvalue())

    def test_invalid_url_port_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["https://example.com:badport"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_query_string_url_rejected(self) -> None:
        self.init()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            code = main(
                [
                    "record",
                    "--run-id",
                    "r1",
                    "--stage",
                    "implement",
                    "--result",
                    str(
                        self.write_result(
                            {
                                "status": "done",
                                "implementedBy": "engineer",
                                "filesChanged": ["src/a.py"],
                                "evidence": ["https://example.com/?token=abc"],
                            }
                        )
                    ),
                    "--repo-root",
                    str(self.root),
                    "--state-dir",
                    str(self.state_dir),
                ]
            )
        self.assertEqual(code, 1)

    def test_utcnow_keeps_sub_second_precision(self) -> None:
        self.assertRegex(utcnow(), r"\.\d{6}\+00:00$")
    def test_budget_blocks_next(self) -> None:
        policy_path = self.root / ".github" / "roles" / "orchestration-policy.json"
        policy = json.loads(policy_path.read_text(encoding="utf-8"))
        policy["retryPolicy"]["maxWallClockMinutes"] = 0.000001
        policy_path.write_text(json.dumps(policy), encoding="utf-8")
        self.init()
        time.sleep(0.05)
        code, payload = self.run_cli(["next", "--run-id", "r1"])
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "wall-clock-budget-exceeded")

    def test_budget_blocks_approve(self) -> None:
        policy_path = self.root / ".github" / "roles" / "orchestration-policy.json"
        policy = json.loads(policy_path.read_text(encoding="utf-8"))
        policy["retryPolicy"]["maxWallClockMinutes"] = 0.000001
        policy_path.write_text(json.dumps(policy), encoding="utf-8")
        self.write_task(approvalCategory="identity-security-change", requestedBy="supervisor")
        self.init()
        time.sleep(0.05)
        code, payload = self.run_cli(
            ["approve", "--run-id", "r1", "--approver", "alice"]
        )
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "wall-clock-budget-exceeded")

    def test_budget_blocker_names_evidence_stage(self) -> None:
        state = {
            "createdAt": "2000-01-01T00:00:00+00:00",
            "stage": "verify",
            "attempt": 2,
            "lastEvidenceStage": "implement",
            "lastEvidence": ["diff:HEAD"],
        }
        policy = {"retryPolicy": {"maxWallClockMinutes": 1}}
        _check_budget(state, policy)
        self.assertEqual(state["stage"], "blocked")
        self.assertIn("implement", state["blocker"]["detail"])

    def test_history_truncation_keeps_init(self) -> None:
        state = {"history": []}
        append_history(state, index=0)
        for index in range(1, HISTORY_LIMIT + 25):
            append_history(state, index=index)
        self.assertEqual(len(state["history"]), HISTORY_LIMIT)
        self.assertEqual(state["history"][0]["index"], 0)
        self.assertEqual(state["historyTruncated"], 25)

    def test_state_persists(self) -> None:
        self.init()
        code, payload = self.run_cli(["status", "--run-id", "r1"])
        self.assertEqual(code, 0)
        self.assertEqual(payload["stage"], "implement")

    def write_result(self, payload: dict) -> Path:
        path = self.root / f"result-{time.time_ns()}.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path


def _add_location_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--repo-root", default=None, help="repository root (default: inferred from this script)")
    parser.add_argument("--state-dir", default=None, help="state directory (default: <repo>/.agentic/state)")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Deterministic task-scoped orchestration engine")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="initialize a run from a task JSON file")
    _add_location_options(init_parser)
    init_parser.add_argument("--run-id", required=True)
    init_parser.add_argument("--task", required=True)
    init_parser.add_argument("--force", action="store_true")
    init_parser.set_defaults(func=cmd_init)

    next_parser = subparsers.add_parser("next", help="show the next action")
    _add_location_options(next_parser)
    next_parser.add_argument("--run-id", required=True)
    next_parser.set_defaults(func=cmd_next)

    status_parser = subparsers.add_parser("status", help="show run status")
    _add_location_options(status_parser)
    status_parser.add_argument("--run-id", required=True)
    status_parser.set_defaults(func=cmd_status)

    report_parser = subparsers.add_parser("report", help="print the full run record")
    _add_location_options(report_parser)
    report_parser.add_argument("--run-id", required=True)
    report_parser.set_defaults(func=cmd_report)

    record_parser = subparsers.add_parser("record", help="record a stage result")
    _add_location_options(record_parser)
    record_parser.add_argument("--run-id", required=True)
    record_parser.add_argument("--stage", required=True, choices=["implement", "repair", "verify", "review"])
    record_parser.add_argument("--result", required=True)
    record_parser.set_defaults(func=cmd_record)

    approve_parser = subparsers.add_parser("approve", help="record human approval")
    _add_location_options(approve_parser)
    approve_parser.add_argument("--run-id", required=True)
    approve_parser.add_argument("--approver", required=True)
    approve_parser.add_argument("--note", default="")
    approve_parser.set_defaults(func=cmd_approve)

    check_tool_parser = subparsers.add_parser(
        "check-tool", help="decide a preToolUse payload read from stdin"
    )
    _add_location_options(check_tool_parser)
    check_tool_parser.set_defaults(func=cmd_check_tool)

    return parser


def main(argv: list | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "selftest":
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(EngineSelfTest)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except EngineError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    except (OSError, ValueError) as exc:
        print(f"[ERROR] {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
