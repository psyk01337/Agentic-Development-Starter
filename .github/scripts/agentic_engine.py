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
import sys
import tempfile
import time
import unittest
from datetime import datetime, timezone
from pathlib import Path

RUN_ID_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
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
            "findings": [{"severity": "string", "summary": "string"}],
            "evidence": ["pointer"],
        },
    },
}


class EngineError(Exception):
    """Invalid input or invalid state transition."""


def utcnow() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


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


def load_state(state_dir: Path, run_id: str) -> dict:
    path = state_path(state_dir, run_id)
    if not path.is_file():
        raise EngineError(f"no state for run-id {run_id} in {state_dir}")
    return json.loads(path.read_text(encoding="utf-8"))


def save_state(state_dir: Path, state: dict) -> None:
    state["updatedAt"] = utcnow()
    atomic_write(state_path(state_dir, state["runId"]), state)


def append_history(state: dict, **entry) -> None:
    record = {"at": utcnow()}
    record.update(entry)
    state.setdefault("history", []).append(record)


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
    missing = []
    for item in evidence:
        if not isinstance(item, str) or not item.strip():
            raise EngineError("evidence entries must be non-empty strings")
        pointer = item.strip()
        pointers.append(pointer)
        if pointer.lower().startswith(EVIDENCE_SCHEMES):
            continue
        candidate = Path(pointer)
        if not candidate.is_absolute():
            candidate = repo_root / candidate
        if not candidate.exists():
            missing.append(pointer)
    if missing:
        raise EngineError(
            "evidence pointers must exist or use a known scheme "
            f"({', '.join(EVIDENCE_SCHEMES)}): {', '.join(missing)}"
        )
    return pointers


def _validate_write_set(write_set) -> None:
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


@contextlib.contextmanager
def run_lock(state_dir: Path, run_id: str):
    """Advisory per-run lock so concurrent records cannot lose updates."""
    state_dir.mkdir(parents=True, exist_ok=True)
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


def validate_task(task: dict, categories: set) -> dict:
    if not isinstance(task, dict):
        raise EngineError("task must be a JSON object")
    for field in ("taskId", "title"):
        if not isinstance(task.get(field), str) or not task[field].strip():
            raise EngineError(f"task.{field} is required")
    criteria = task.get("acceptanceCriteria")
    if not isinstance(criteria, list) or not criteria:
        raise EngineError("task.acceptanceCriteria must be a non-empty list")
    _validate_write_set(task.get("writeSet"))
    category = task.get("approvalCategory")
    if category is not None and category not in categories:
        raise EngineError(f"task.approvalCategory is not a known category: {category}")
    requested_by = task.get("requestedBy")
    if category is not None and (not isinstance(requested_by, str) or not requested_by.strip()):
        raise EngineError("task.requestedBy is required when task.approvalCategory is set")
    task.setdefault("class", "FEATURE")
    task.setdefault("complexity", "simple")
    task.setdefault("evidenceSurfaces", [])
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
    return payload


def cmd_init(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else repo_root_from(Path(__file__))
    policy = load_policy(repo_root)
    categories = approval_categories(policy)
    task = validate_task(read_json_file(args.task), categories)
    state_dir = state_dir_for(repo_root, args.state_dir)
    path = state_path(state_dir, args.run_id)
    with run_lock(state_dir, args.run_id):
        if path.exists() and not args.force:
            raise EngineError(f"state already exists for run-id {args.run_id}; use --force to replace")
        if path.exists() and args.force:
            previous = json.loads(path.read_text(encoding="utf-8"))
            if previous.get("stage") == "done":
                raise EngineError(
                    "refusing to replace a completed run; use a new run-id to preserve the audit trail"
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
    state_dir = state_dir_for(repo_root, args.state_dir)
    state = load_state(state_dir, args.run_id)
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
            "blocker": state.get("blocker"),
            "historyLength": len(state.get("history", [])),
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
    return 0


def _check_budget(state: dict, policy: dict) -> None:
    limits = retry_policy(policy)
    limit = limits.get("maxWallClockMinutes")
    if isinstance(limit, (int, float)) and limit > 0 and minutes_elapsed(state) > limit:
        block(
            state,
            "wall-clock-budget-exceeded",
            f"run exceeded the {limit}-minute wall-clock budget",
            state.get("lastEvidence", []),
        )


def _normalize_path(value: str) -> str:
    return str(value).strip().replace("\\", "/").removeprefix("./").lower()


def _outside_write_set(files: list, write_set: list) -> list:
    allowed = {_normalize_path(item) for item in write_set}
    return [str(item) for item in files if _normalize_path(str(item)) not in allowed]


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

    if args.stage in ("implement", "repair"):
        if result.get("status") != "done":
            raise EngineError("implement/repair result must set status to 'done'")
        files = result.get("filesChanged") or []
        if not isinstance(files, list):
            raise EngineError("filesChanged must be a list")
        if not all(isinstance(item, str) and item.strip() for item in files):
            raise EngineError("filesChanged entries must be non-empty strings")
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
        state["stage"] = "verify"
        state["status"] = "RUNNING"
        append_history(state, stage=args.stage, action="recorded", files=files, evidence=evidence)

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
        findings = result.get("findings")
        if not isinstance(findings, list):
            raise EngineError("review result must include a findings list")
        if decision == "needs-revision" and not findings:
            raise EngineError("a needs-revision review must name at least one finding")
        append_history(state, stage="review", action="recorded", decision=decision, evidence=evidence)
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
    state_dir = state_dir_for(repo_root, args.state_dir)
    with run_lock(state_dir, args.run_id):
        state = load_state(state_dir, args.run_id)
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
            {"status": "done", "filesChanged": ["src/a.py"], "evidence": ["diff:HEAD"]},
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
            "review", {"decision": "pass", "findings": [], "evidence": ["cmd:review"]}
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
                {"status": "done", "filesChanged": ["src/a.py"], "evidence": ["diff:HEAD"]},
            )[1]["stage"],
            "verify",
        )
        self.assertEqual(self.verify("VERIFIED", [{"name": "pytest", "ok": True}])[1]["stage"], "review")

    def test_identical_failure_escalates(self) -> None:
        self.init()
        self.implement()
        self.verify("NOT_VERIFIED", [{"name": "pytest", "ok": False, "message": "same"}])
        self.record(
            "repair", {"status": "done", "filesChanged": ["src/a.py"], "evidence": ["diff:HEAD"]}
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
            "repair", {"status": "done", "filesChanged": ["src/a.py"], "evidence": ["diff:HEAD"]}
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
                {"status": "done", "filesChanged": ["src/a.py"], "evidence": ["diff:HEAD"]},
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
            {"status": "done", "filesChanged": ["src/other.py"], "evidence": ["diff:HEAD"]},
        )
        self.assertEqual(code, 3)
        self.assertEqual(payload["blocker"]["reason"], "write-set-violation")

    def test_write_set_violation_with_normalized_path_passes(self) -> None:
        self.init()
        code, _ = self.record(
            "implement",
            {"status": "done", "filesChanged": ["./src/a.py"], "evidence": ["diff:HEAD"]},
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
                    str(self.write_result({"decision": "pass", "findings": [], "evidence": []})),
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
                    str(self.write_result({"decision": "needs-revision", "findings": [], "evidence": ["cmd:r"]})),
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
                    str(self.write_result({"status": "done", "filesChanged": []})),
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
        self.record("review", {"decision": "pass", "findings": [], "evidence": ["cmd:review"]})
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


if __name__ == "__main__":
    sys.exit(main())
