#!/usr/bin/env python3
"""SDK-driven execution with engine-mediated permissions.

This module owns the outer loop: ask the engine what stage is required, let an
executor work that stage, record the result, and repeat until the engine says
done or blocked. It never decides whether work is acceptable - that stays in
agentic_engine.py.

The security property lives in PermissionGateway. Every tool call the executor
wants to make is classified, checked against the current stage, and - for writes
- checked against the declared write set. Anything unclassified is denied. A
gateway that is consulted but not obeyed is worse than none, so the loop only
proceeds when the gateway permits, and a denial is terminal for that attempt.

Usage:
    python agentic_driver.py selftest
    python agentic_driver.py plan --run-id <id> [--repo-root PATH]

The Copilot SDK adapter is not wired here. See docs/adr/0008 and the runbook:
wiring it needs credentials this repository does not carry.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Iterable

ENGINE = Path(__file__).with_name("agentic_engine.py")

# What each stage may do. Read is universal; running checks is allowed wherever
# evidence is produced; writing is allowed only where the stage exists to change
# code. Anything not listed is denied.
STAGE_PROFILES = {
    "approval": {"read": True, "run": False, "write": False},
    "implement": {"read": True, "run": True, "write": True},
    "repair": {"read": True, "run": True, "write": True},
    "verify": {"read": True, "run": True, "write": False},
    "review": {"read": True, "run": True, "write": False},
    "blocked": {"read": True, "run": False, "write": False},
    "done": {"read": True, "run": False, "write": False},
}

# Classification is explicit. Inferring a tool kind from its name would let a
# rename bypass the stage check, so an unlisted tool is denied rather than
# guessed at.
TOOL_KINDS = {
    "read_file": "read",
    "list_files": "read",
    "search_files": "read",
    "write_file": "write",
    "edit_file": "write",
    "delete_file": "write",
    "run_command": "run",
}

PATH_ARGUMENT = "path"

SHELL_METACHARACTERS = (";", "|", "&", "$(", "`", ">", "<", "\n")


class DriverError(RuntimeError):
    """Raised for a driver-level misuse, not a permission denial."""


@dataclass
class Decision:
    allowed: bool
    reason: str
    stage: str
    tool: str
    kind: str

    def as_dict(self) -> dict:
        return {
            "allowed": self.allowed,
            "reason": self.reason,
            "stage": self.stage,
            "tool": self.tool,
            "kind": self.kind,
        }


def normalize_path(value: str) -> str:
    normalized = str(value).strip().replace("\\", "/")
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


class PermissionGateway:
    """Decides whether a tool call may proceed at the current stage."""

    def __init__(self, write_set: Iterable[str], stage: str) -> None:
        if stage not in STAGE_PROFILES:
            raise DriverError(f"unknown stage for permission: {stage!r}")
        self.stage = stage
        self.write_set = {normalize_path(item) for item in write_set}
        self.denials: list[Decision] = []

    def evaluate(self, tool: str, arguments: dict | None = None) -> Decision:
        arguments = arguments or {}
        kind = TOOL_KINDS.get(tool)
        profile = STAGE_PROFILES[self.stage]

        if kind is None:
            return self._deny(tool, "unknown", f"tool {tool!r} is not classified")

        if not profile.get(kind, False):
            return self._deny(
                tool, kind, f"stage {self.stage!r} does not permit {kind} operations"
            )

        if kind == "write":
            path = arguments.get(PATH_ARGUMENT)
            if not isinstance(path, str) or not path.strip():
                return self._deny(
                    tool, kind, f"write tool {tool!r} did not name a {PATH_ARGUMENT!r}"
                )
            if normalize_path(path) not in self.write_set:
                return self._deny(
                    tool, kind, f"{path!r} is outside the declared write set"
                )

        if kind == "run":
            command = arguments.get("command")
            if isinstance(command, str) and any(
                token in command for token in SHELL_METACHARACTERS
            ):
                return self._deny(
                    tool,
                    kind,
                    "command contains shell metacharacters; pass an argv list instead",
                )

        return Decision(True, "permitted", self.stage, tool, kind)

    def _deny(self, tool: str, kind: str, reason: str) -> Decision:
        decision = Decision(False, reason, self.stage, tool, kind)
        self.denials.append(decision)
        return decision


@dataclass
class StageResult:
    """What an executor returns for one stage."""

    payload: dict
    notes: list[str] = field(default_factory=list)


class Executor:
    """Works one stage and returns the result payload to record."""

    def run_stage(self, stage: str, payload: dict, gateway: PermissionGateway) -> StageResult:
        raise NotImplementedError


class ScriptedExecutor(Executor):
    """Replays canned stage results. Used by the self-tests and for dry runs."""

    def __init__(self, results: dict[str, dict]) -> None:
        self.results = results
        self.stages_worked: list[str] = []

    def run_stage(self, stage: str, payload: dict, gateway: PermissionGateway) -> StageResult:
        if stage not in self.results:
            raise DriverError(f"no scripted result for stage {stage!r}")
        self.stages_worked.append(stage)
        return StageResult(dict(self.results[stage]))


class CopilotSdkExecutor(Executor):
    """Adapter for @github/copilot-sdk.

    Not implemented. The SDK is an optional dependency and needs Copilot
    credentials or a BYOK key, neither of which this repository carries. The
    failure is explicit so a caller cannot mistake a missing adapter for a
    working loop.
    """

    def run_stage(self, stage: str, payload: dict, gateway: PermissionGateway) -> StageResult:
        raise DriverError(
            "the Copilot SDK adapter is not wired: install the SDK and supply "
            "credentials, then implement CopilotSdkExecutor.run_stage against "
            "your permission handler"
        )


class EngineClient:
    """Thin wrapper over the engine CLI. Always an argv list, never a shell."""

    def __init__(self, repo_root: Path, state_dir: Path | None = None, run_id: str = "") -> None:
        self.repo_root = repo_root
        self.state_dir = state_dir
        self.run_id = run_id

    def _engine_path(self) -> Path:
        """Prefer the engine inside the target repo, else the one beside us."""
        candidate = self.repo_root / ".github" / "scripts" / "agentic_engine.py"
        return candidate if candidate.is_file() else ENGINE

    def _call(self, argv: list) -> tuple[int, dict]:
        full = [sys.executable, str(self._engine_path())] + argv
        full += ["--repo-root", str(self.repo_root)]
        if self.state_dir is not None:
            full += ["--state-dir", str(self.state_dir)]
        completed = subprocess.run(full, capture_output=True, text=True, timeout=300, check=False)
        text = (completed.stdout or "").strip()
        try:
            payload = json.loads(text) if text else {}
        except json.JSONDecodeError:
            payload = {"raw": text}
        return completed.returncode, payload

    def next(self) -> tuple[int, dict]:
        return self._call(["next", "--run-id", self.run_id])

    def status(self) -> tuple[int, dict]:
        return self._call(["status", "--run-id", self.run_id])

    def record(self, stage: str, result_path: Path) -> tuple[int, dict]:
        return self._call(
            ["record", "--run-id", self.run_id, "--stage", stage, "--result", str(result_path)]
        )


def run_loop(
    engine: EngineClient,
    executor: Executor,
    write_set: Iterable[str],
    max_stages: int = 20,
    on_permission: Callable[[Decision], None] | None = None,
    result_dir: Path | None = None,
) -> dict:
    """Drive stages until the engine reports done or blocked.

    Every stage gets a fresh gateway because the permitted operations change with
    the stage. A denial never aborts the loop silently: it is returned so a caller
    can act on it.
    """
    worked: list[str] = []
    denials: list[dict] = []
    for _ in range(max_stages):
        code, payload = engine.next()
        stage = payload.get("stage")
        if not stage:
            return {"outcome": "error", "detail": "engine returned no stage", "payload": payload}
        if stage in ("done", "blocked"):
            return {
                "outcome": stage,
                "stages": worked,
                "denials": denials,
                "payload": payload,
            }

        gateway = PermissionGateway(write_set, stage)
        try:
            result = executor.run_stage(stage, payload, gateway)
        except DriverError as exc:
            return {"outcome": "error", "detail": str(exc), "stages": worked, "denials": denials}

        for decision in gateway.denials:
            if on_permission is not None:
                on_permission(decision)
            denials.append(decision.as_dict())

        target = (result_dir or Path(".")) / f"driver-{stage}.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(result.payload), encoding="utf-8")
        record_code, record_payload = engine.record(stage, target)
        worked.append(stage)
        if record_code not in (0, 3):
            return {
                "outcome": "error",
                "detail": f"engine rejected the {stage} record",
                "stages": worked,
                "denials": denials,
                "payload": record_payload,
            }
        if record_code == 3:
            return {
                "outcome": "blocked",
                "stages": worked,
                "denials": denials,
                "payload": record_payload,
            }
    return {"outcome": "budget", "detail": "stage budget exhausted", "stages": worked, "denials": denials}


def cmd_plan(args: argparse.Namespace) -> int:
    repo_root = Path(args.repo_root).resolve() if args.repo_root else Path(__file__).resolve().parents[2]
    engine = EngineClient(repo_root, None, args.run_id)
    code, payload = engine.status()
    if code not in (0, 3):
        print(f"[ERROR] engine status failed with exit {code}", file=sys.stderr)
        return 1
    stage = payload.get("stage", "unknown")
    profile = STAGE_PROFILES.get(stage, {"read": True, "run": False, "write": False})
    print(json.dumps({"stage": stage, "permissions": profile}, indent=2))
    return 0


class PermissionGatewayTest(unittest.TestCase):
    WRITE_SET = ["src/a.py", "src/nested/b.py"]

    def gateway(self, stage: str) -> PermissionGateway:
        return PermissionGateway(self.WRITE_SET, stage)

    # --- deny by default -----------------------------------------------------

    def test_unknown_tool_is_denied(self) -> None:
        decision = self.gateway("implement").evaluate("frobnicate", {})
        self.assertFalse(decision.allowed)
        self.assertEqual(decision.kind, "unknown")
        self.assertIn("not classified", decision.reason)

    def test_read_is_allowed_at_every_stage(self) -> None:
        for stage in STAGE_PROFILES:
            with self.subTest(stage=stage):
                self.assertTrue(self.gateway(stage).evaluate("read_file", {}).allowed)

    # --- stage gating --------------------------------------------------------

    def test_write_denied_at_verify(self) -> None:
        decision = self.gateway("verify").evaluate("write_file", {"path": "src/a.py"})
        self.assertFalse(decision.allowed)
        self.assertIn("does not permit write", decision.reason)

    def test_write_denied_at_review(self) -> None:
        self.assertFalse(
            self.gateway("review").evaluate("edit_file", {"path": "src/a.py"}).allowed
        )

    def test_write_denied_at_approval(self) -> None:
        self.assertFalse(
            self.gateway("approval").evaluate("write_file", {"path": "src/a.py"}).allowed
        )

    def test_run_denied_at_approval(self) -> None:
        self.assertFalse(
            self.gateway("approval").evaluate("run_command", {"command": ["pytest"]}).allowed
        )

    def test_write_allowed_at_implement_inside_write_set(self) -> None:
        self.assertTrue(
            self.gateway("implement").evaluate("write_file", {"path": "src/a.py"}).allowed
        )

    def test_write_allowed_at_repair(self) -> None:
        self.assertTrue(
            self.gateway("repair").evaluate("edit_file", {"path": "src/nested/b.py"}).allowed
        )

    # --- write-set containment ----------------------------------------------

    def test_write_denied_outside_write_set(self) -> None:
        decision = self.gateway("implement").evaluate("write_file", {"path": "src/other.py"})
        self.assertFalse(decision.allowed)
        self.assertIn("outside the declared write set", decision.reason)

    def test_write_denied_for_path_traversal(self) -> None:
        self.assertFalse(
            self.gateway("implement").evaluate("write_file", {"path": "../escape.py"}).allowed
        )

    def test_write_path_normalization_matches_engine(self) -> None:
        self.assertTrue(
            self.gateway("implement").evaluate("write_file", {"path": "./src/a.py"}).allowed
        )
        self.assertTrue(
            self.gateway("implement").evaluate("write_file", {"path": "src\\a.py"}).allowed
        )

    def test_write_without_path_denied(self) -> None:
        decision = self.gateway("implement").evaluate("write_file", {})
        self.assertFalse(decision.allowed)
        self.assertIn("did not name", decision.reason)

    def test_delete_is_treated_as_a_write(self) -> None:
        self.assertFalse(
            self.gateway("verify").evaluate("delete_file", {"path": "src/a.py"}).allowed
        )

    # --- command safety ------------------------------------------------------

    def test_command_with_shell_metacharacters_denied(self) -> None:
        for command in ("pytest; rm -rf /", "pytest | tee log", "echo $(whoami)"):
            with self.subTest(command=command):
                self.assertFalse(
                    self.gateway("verify").evaluate("run_command", {"command": command}).allowed
                )

    def test_plain_command_allowed_at_verify(self) -> None:
        self.assertTrue(
            self.gateway("verify").evaluate("run_command", {"command": "pytest -q"}).allowed
        )

    # --- denials are observable ---------------------------------------------

    def test_denials_are_retained(self) -> None:
        gateway = self.gateway("verify")
        gateway.evaluate("write_file", {"path": "src/a.py"})
        gateway.evaluate("nonsense", {})
        self.assertEqual(len(gateway.denials), 2)
        self.assertTrue(all(not decision.allowed for decision in gateway.denials))

    def test_unknown_stage_rejected_at_construction(self) -> None:
        with self.assertRaises(DriverError):
            PermissionGateway(self.WRITE_SET, "shipping")


class FakeEngine:
    """Stands in for EngineClient so the loop is testable without a repo."""

    def __init__(self, stages: list, blocked_on: str | None = None) -> None:
        self.stages = stages
        self.blocked_on = blocked_on
        self.recorded: list[str] = []

    def next(self) -> tuple[int, dict]:
        if self.blocked_on is not None:
            return 3, {"stage": "blocked", "reason": self.blocked_on}
        if not self.stages:
            return 0, {"stage": "done"}
        return 0, {"stage": self.stages[0]}

    def record(self, stage: str, result_path) -> tuple[int, dict]:
        self.recorded.append(stage)
        if self.stages:
            self.stages.pop(0)
        return 0, {"stage": self.stages[0] if self.stages else "done"}


class RunLoopTest(unittest.TestCase):
    def test_loop_drives_to_done(self) -> None:
        engine = FakeEngine(["implement", "verify", "review"])
        executor = ScriptedExecutor(
            {
                "implement": {"status": "done", "implementedBy": "dev", "filesChanged": ["src/a.py"], "evidence": ["diff:HEAD"]},
                "verify": {"result": "VERIFIED", "checks": [{"name": "pytest", "ok": True}], "evidence": ["test:pytest"]},
                "review": {"decision": "pass", "reviewedBy": "reviewer", "findings": [], "evidence": ["diff:HEAD"]},
            }
        )
        with tempfile.TemporaryDirectory() as tmp:
            outcome = run_loop(engine, executor, ["src/a.py"], result_dir=Path(tmp))
        self.assertEqual(outcome["outcome"], "done")
        self.assertEqual(outcome["stages"], ["implement", "verify", "review"])
        self.assertEqual(engine.recorded, ["implement", "verify", "review"])
        self.assertEqual(outcome["denials"], [])

    def test_loop_surfaces_a_blocked_run(self) -> None:
        engine = FakeEngine([], blocked_on="identical-failure")
        outcome = run_loop(engine, ScriptedExecutor({}), ["src/a.py"], result_dir=Path(tempfile.mkdtemp()))
        self.assertEqual(outcome["outcome"], "blocked")
        self.assertEqual(outcome["payload"]["reason"], "identical-failure")

    def test_loop_reports_denials_from_a_stage(self) -> None:
        class ProbingExecutor(Executor):
            def run_stage(self, stage, payload, gateway):
                gateway.evaluate("write_file", {"path": "src/a.py"})
                return StageResult({"result": "VERIFIED", "checks": [{"name": "c", "ok": True}], "evidence": ["test:x"]})

        engine = FakeEngine(["verify"])
        with tempfile.TemporaryDirectory() as tmp:
            outcome = run_loop(engine, ProbingExecutor(), ["src/a.py"], result_dir=Path(tmp))
        self.assertEqual(len(outcome["denials"]), 1)
        self.assertIn("does not permit write", outcome["denials"][0]["reason"])

    def test_loop_stops_at_stage_budget(self) -> None:
        engine = FakeEngine(["implement"] * 5)
        executor = ScriptedExecutor(
            {"implement": {"status": "done", "implementedBy": "dev", "filesChanged": [], "evidence": ["diff:HEAD"]}}
        )
        with tempfile.TemporaryDirectory() as tmp:
            outcome = run_loop(engine, executor, [], max_stages=3, result_dir=Path(tmp))
        self.assertEqual(outcome["outcome"], "budget")

    def test_missing_scripted_result_is_an_error_not_a_silent_pass(self) -> None:
        engine = FakeEngine(["verify"])
        with tempfile.TemporaryDirectory() as tmp:
            outcome = run_loop(engine, ScriptedExecutor({}), [], result_dir=Path(tmp))
        self.assertEqual(outcome["outcome"], "error")


class SdkAdapterTest(unittest.TestCase):
    def test_sdk_executor_fails_loudly_rather_than_pretending(self) -> None:
        with self.assertRaises(DriverError) as caught:
            CopilotSdkExecutor().run_stage("implement", {}, PermissionGateway([], "implement"))
        self.assertIn("not wired", str(caught.exception))

def cmd_selftest(_: argparse.Namespace) -> int:
    import unittest

    return 0 if unittest.main(module=__name__, argv=["selftest", "-q"], exit=False).result.wasSuccessful() else 1


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(description="SDK-driven execution with engine-mediated permissions")
    sub = parser.add_subparsers(dest="command", required=True)
    plan = sub.add_parser("plan", help="show the current stage and what it permits")
    plan.add_argument("--run-id", required=True)
    plan.add_argument("--repo-root")
    plan.set_defaults(func=cmd_plan)
    selftest = sub.add_parser("selftest", help="run the driver self-tests")
    selftest.set_defaults(func=cmd_selftest)
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except (DriverError, OSError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
