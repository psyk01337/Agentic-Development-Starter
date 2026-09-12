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

assert_file_exists() {
  local relative_path="$1"
  if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
    report_error "Missing required file: ${relative_path}"
  fi
}

assert_file_contains() {
  local relative_path="$1"
  local pattern="$2"
  local description="$3"

  if [[ ! -f "${REPO_ROOT}/${relative_path}" ]]; then
    report_error "Cannot verify ${description} because file is missing: ${relative_path}"
    return
  fi

  if ! grep -Eq "${pattern}" "${REPO_ROOT}/${relative_path}"; then
    report_error "Missing expected content for ${description} in ${relative_path}"
  fi
}

required_files=(
  ".github/agents/delegation-supervisor.agent.md"
  ".github/skills/supervisor-orchestration/SKILL.md"
  ".github/roles/orchestration-policy.json"
  ".github/schema/delegation-plan.schema.json"
  ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json"
  ".github/scripts/check-supervisor-orchestration.ps1"
  ".github/scripts/check-supervisor-orchestration.sh"
  "docs/runbooks/supervisor-orchestration.md"
  "docs/adr/0003-supervisor-orchestration-overlay.md"
)

for relative_path in "${required_files[@]}"; do
  assert_file_exists "${relative_path}"
done

if ! python3 - "${REPO_ROOT}" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
errors = []


def load(relative_path):
    return json.loads((root / relative_path).read_text(encoding="utf-8"))


def validate_instance(instance, schema, path="$"):
    """Evaluate the JSON Schema subset used by the delegation-plan schema."""
    problems = []
    for subschema in schema.get("allOf", []):
        problems.extend(validate_instance(instance, subschema, path))
    if "if" in schema and not validate_instance(instance, schema["if"], path):
        problems.extend(validate_instance(instance, schema.get("then", {}), path))

    expected_type = schema.get("type")
    if expected_type is not None:
        matched = (
            (expected_type == "object" and isinstance(instance, dict))
            or (expected_type == "array" and isinstance(instance, list))
            or (expected_type == "string" and isinstance(instance, str))
            or (expected_type == "boolean" and isinstance(instance, bool))
        )
        if not matched:
            return problems + [f"{path}: expected {expected_type}"]

    if isinstance(instance, dict):
        properties = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in instance:
                problems.append(f"{path}: missing required property '{key}'")
        if schema.get("additionalProperties") is False:
            for key in instance:
                if key not in properties:
                    problems.append(f"{path}: unexpected property '{key}'")
        for key, value in instance.items():
            if key in properties:
                problems.extend(validate_instance(value, properties[key], f"{path}.{key}"))
    elif isinstance(instance, list):
        if "minItems" in schema and len(instance) < schema["minItems"]:
            problems.append(f"{path}: fewer than minItems {schema['minItems']}")
        item_schema = schema.get("items")
        if item_schema:
            for index, item in enumerate(instance):
                problems.extend(validate_instance(item, item_schema, f"{path}[{index}]"))
    elif isinstance(instance, str):
        if "minLength" in schema and len(instance) < schema["minLength"]:
            problems.append(f"{path}: shorter than minLength {schema['minLength']}")

    if "const" in schema and instance != schema["const"]:
        problems.append(f"{path}: expected const {schema['const']!r}")
    if "enum" in schema and instance not in schema["enum"]:
        problems.append(f"{path}: value {instance!r} is not in the schema enum")
    return problems


manifest = load(".github/starter-modules.json")
overlay = next(
    (module for module in manifest.get("modules", []) if module.get("id") == "overlay-supervisor-orchestration"),
    None,
)
if overlay is None:
    errors.append("starter-modules.json is missing overlay-supervisor-orchestration")
else:
    if overlay.get("kind") != "overlay":
        errors.append("overlay-supervisor-orchestration must have kind 'overlay'")
    if overlay.get("defaultEnabled") is not False:
        errors.append("overlay-supervisor-orchestration must be default-disabled")
    for relative_path in overlay.get("files", []):
        if not (root / relative_path).exists():
            errors.append(f"Manifest-listed overlay file does not exist: {relative_path}")

access = load(".github/roles/tool-access.json")
tool_definitions = access.get("toolDefinitions", {})
roles = access.get("roles", {})
matrix = access.get("agentCapabilityMatrix", {})
hints = access.get("agentRoleHints", {})

if "delegate-agent" not in tool_definitions:
    errors.append("tool-access.json toolDefinitions is missing delegate-agent")

expected_role_tools = {"read", "search", "todo", "delegate-agent"}
if "orchestration" not in roles:
    errors.append("tool-access.json roles is missing the orchestration role")
else:
    role_tools = set(roles["orchestration"].get("tools", []))
    if role_tools != expected_role_tools:
        errors.append(
            "orchestration role tools must be exactly "
            f"{sorted(expected_role_tools)}; found {sorted(role_tools)}"
        )
    for forbidden in ("edit", "execute"):
        if forbidden in role_tools:
            errors.append(f"orchestration role must not include {forbidden}")

supervisor = matrix.get("delegation-supervisor")
if not supervisor:
    errors.append("agentCapabilityMatrix is missing delegation-supervisor")
else:
    if supervisor.get("role") != "orchestration":
        errors.append("delegation-supervisor must use the orchestration role")
    tools = supervisor.get("tools", {})
    if tools.get("delegate-agent") is not True:
        errors.append("delegation-supervisor must hold delegate-agent")
    if tools.get("edit") is not False:
        errors.append("delegation-supervisor must not hold edit")
    if tools.get("execute") is not False:
        errors.append("delegation-supervisor must not hold execute")
    for required in ("read", "search", "todo"):
        if tools.get(required) is not True:
            errors.append(f"delegation-supervisor must declare {required}")

if hints.get("delegation-supervisor") != "orchestration":
    errors.append("agentRoleHints must map delegation-supervisor to orchestration")
for agent_name, hint_role in sorted(hints.items()):
    matrix_role = matrix.get(agent_name, {}).get("role")
    if matrix_role is not None and matrix_role != hint_role:
        errors.append(
            "agentRoleHints entry disagrees with agentCapabilityMatrix role for "
            f"{agent_name}: hint {hint_role}, matrix {matrix_role}"
        )

for name, role in roles.items():
    if name != "orchestration" and "delegate-agent" in role.get("tools", []):
        errors.append(f"only the orchestration role may hold delegate-agent; found in {name}")
for name, entry in matrix.items():
    if name != "delegation-supervisor" and entry.get("tools", {}).get("delegate-agent"):
        errors.append(f"only delegation-supervisor may hold delegate-agent; found in {name}")

policy = load(".github/roles/orchestration-policy.json")
depth = policy.get("delegationDepth", {})
if depth.get("maxLevels") != 1:
    errors.append("orchestration-policy.json must set delegationDepth.maxLevels to 1")
if depth.get("nestedDelegationEnabled") is not False:
    errors.append("orchestration-policy.json must disable nested delegation")
if depth.get("onlySupervisorMayDelegate") is not True:
    errors.append("orchestration-policy.json must restrict delegation to the supervisor")
if depth.get("workersMayDelegate") is not False:
    errors.append("orchestration-policy.json must deny worker delegation (workersMayDelegate: false)")
if policy.get("enforcement", {}).get("runtimeEnforced") is not False:
    errors.append(
        "orchestration-policy.json must not claim runtime enforcement (enforcement.runtimeEnforced: false)"
    )
if policy.get("writeSet", {}).get("requiredBeforeWriteDelegation") is not True:
    errors.append("orchestration-policy.json must require a declared write set before write delegation")
if policy.get("fallbackWhenDelegationUnavailable", {}).get("silentDegradationAllowed") is not False:
    errors.append(
        "orchestration-policy.json must forbid silent degradation (silentDegradationAllowed: false)"
    )
if policy.get("deferredProposal", {}).get("status") != "deferred-not-rejected":
    errors.append("orchestration-policy.json must keep the deferred proposal as 'deferred-not-rejected'")
if policy.get("approvalOverlayComposition", {}).get("hardDependency") is not False:
    errors.append("orchestration-policy.json must not declare a hard dependency on the approval overlay")

allow_list = policy.get("specialistAllowList", [])
if not allow_list:
    errors.append("orchestration-policy.json must define a specialist allow-list")
for required_agent in (
    "analyst",
    "tech-planner",
    "architecture-reviewer",
    "senior-software-engineer",
    "code-reviewer",
    "security-reviewer",
    "qa",
    "tdd-vitest",
    "documentation-maintainer",
):
    if required_agent not in allow_list:
        errors.append(f"specialist allow-list is missing {required_agent}")

categories = {category.get("id") for category in policy.get("approvalRequiredCategories", [])}
for required_category in (
    "architecture-change",
    "core-governance-change",
    "dependency-change",
    "destructive-data-change",
    "identity-security-change",
    "production-or-deployment-change",
    "destructive-operation",
    "scope-expansion",
):
    if required_category not in categories:
        errors.append(f"approval-required categories are missing {required_category}")

schema = load(".github/schema/delegation-plan.schema.json")
example = load(".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json")
errors.extend(validate_instance(example, schema))

unbounded_indicators = {
    indicator.strip().casefold()
    for indicator in policy.get("writeSet", {}).get("unboundedIndicators", [])
}
for index, delegation in enumerate(example.get("delegations", [])):
    for entry in delegation.get("writeSet", []) or []:
        if isinstance(entry, str) and entry.strip().casefold() in unbounded_indicators:
            errors.append(
                f"delegations[{index}].writeSet declares an unbounded indicator '{entry}'; "
                "serialize the write delegation instead of running it in parallel"
            )

schema_allow_list = (
    schema.get("properties", {})
    .get("delegations", {})
    .get("items", {})
    .get("properties", {})
    .get("agent", {})
    .get("enum", [])
)
if sorted(schema_allow_list) != sorted(allow_list):
    errors.append(
        "delegation-plan.schema.json agent enum has drifted from the canonical policy allow-list"
    )

# Sole-holder invariant, checked over every agent file rather than only the
# capability matrix. A new agent file can appear without a matrix entry, so the
# frontmatter scan is the authoritative path and the matrix must then agree with
# it, in both directions.
agents_dir = root / ".github/agents"
agent_files = sorted(agents_dir.glob("*.agent.md"))
if not agent_files:
    errors.append("No agent files found under .github/agents")

frontmatter_tools = {}
agents_without_tools_list = set()
for agent_path in agent_files:
    agent_name = agent_path.name[: -len(".agent.md")]
    agent_text = agent_path.read_text(encoding="utf-8")
    match = re.search(r"^tools:\s*\[([^\]]*)\]", agent_text, re.MULTILINE)
    if not match:
        # tools: is optional in .agent.md frontmatter, so an unregistered agent
        # file is not required to declare one. Only a registered capability
        # boundary makes the list load-bearing.
        agents_without_tools_list.add(agent_name)
        continue
    frontmatter_tools[agent_name] = {
        item.strip() for item in match.group(1).split(",") if item.strip()
    }

supervisor_tools = frontmatter_tools.get("delegation-supervisor")
if supervisor_tools is not None and supervisor_tools != expected_role_tools:
    errors.append(
        "delegation-supervisor frontmatter tools must be exactly "
        f"{', '.join(sorted(expected_role_tools))}; "
        f"found {', '.join(sorted(supervisor_tools))}"
    )

for agent_name in sorted(frontmatter_tools):
    if agent_name != "delegation-supervisor" and "delegate-agent" in frontmatter_tools[agent_name]:
        errors.append(
            "only delegation-supervisor may declare delegate-agent in agent frontmatter; "
            f"found in {agent_name}"
        )

for agent_name in sorted(matrix):
    if agent_name not in frontmatter_tools:
        if agent_name in agents_without_tools_list:
            errors.append(
                f"{agent_name} agent is registered in agentCapabilityMatrix "
                "but declares no tools frontmatter list"
            )
        else:
            errors.append(f"agentCapabilityMatrix entry has no agent file: {agent_name}")
        continue
    matrix_tools = matrix[agent_name].get("tools", {})
    unknown_enabled = sorted(
        tool
        for tool, enabled in matrix_tools.items()
        if enabled is True and tool not in tool_definitions
    )
    if unknown_enabled:
        errors.append(
            f"{agent_name} agentCapabilityMatrix enables tools that are absent from "
            f"toolDefinitions: {', '.join(unknown_enabled)}"
        )
    declared_tools = {
        tool
        for tool, enabled in matrix_tools.items()
        if tool in tool_definitions and enabled is True
    }
    if declared_tools != frontmatter_tools[agent_name]:
        errors.append(
            f"{agent_name} frontmatter tools do not match agentCapabilityMatrix tools: "
            f"frontmatter {', '.join(sorted(frontmatter_tools[agent_name]))}, "
            f"matrix {', '.join(sorted(declared_tools))}"
        )

for agent_name in sorted(frontmatter_tools):
    if "delegate-agent" in frontmatter_tools[agent_name] and agent_name in allow_list:
        errors.append(
            f"specialist allow-list must not list the delegation-capable agent {agent_name}"
        )

# The hook-inheritance precondition withholds a capability rather than blocking
# enablement, so it needs a delegation surface it can withhold *to*. If an edit
# leaves every allow-listed agent able to mutate state, the capability-scoped
# rule degrades into a total block that the runbook and ADR both say it is not.
# This proves the tier is defined, never that it was used.
non_mutating_capabilities = {"read", "search", "todo"}
non_mutating_tier = sorted(
    agent_name
    for agent_name, agent_tools in frontmatter_tools.items()
    if agent_name in allow_list and agent_tools <= non_mutating_capabilities
)
if not non_mutating_tier:
    errors.append(
        "specialist allow-list has no non-mutating tier: no allow-listed agent declares "
        "capabilities within read, search, todo, so an unverified hook-inheritance result "
        "would withhold delegation entirely instead of scoping it"
    )

# The approval gate is a prompt-level contract, not enforcement. Guard the
# shipped governance text - the agent catalog, every agent file, and the role
# and scope intents in tool-access.json - against drifting back into an
# enforcement claim. A line is a claim when it names the boundary and uses an
# enforcement word without also negating it.
enforcement_word = re.compile(r"enforc\w*", re.IGNORECASE)
boundary_topic = re.compile(r"high-risk approval|approval boundary", re.IGNORECASE)
negated_enforcement = re.compile(
    r"not enforc|non-enforc|no enforc|rather than enforc|instead of enforc",
    re.IGNORECASE,
)

governance_files = [".github/AGENTS.md", ".github/roles/tool-access.json"]
governance_files.extend(f".github/agents/{agent_path.name}" for agent_path in agent_files)
for relative_path in governance_files:
    governance_path = root / relative_path
    if not governance_path.exists():
        continue
    governance_text = governance_path.read_text(encoding="utf-8")
    for number, line in enumerate(governance_text.splitlines(), start=1):
        if (
            boundary_topic.search(line)
            and enforcement_word.search(line)
            and not negated_enforcement.search(line)
        ):
            errors.append(
                f"{relative_path}:{number} must not describe the supervisor "
                "approval gate as enforcement"
            )

if errors:
    for message in errors:
        print(f"[ERROR] {message}", file=sys.stderr)
    sys.exit(1)
PY
then
  FAILED=1
fi

assert_file_contains ".github/AGENTS.md" "delegation-supervisor" "supervisor agent catalog entry"
assert_file_contains ".github/AGENTS.md" "orchestration-coordinator" "coordinator role distinction"
assert_file_contains ".github/AGENTS.md" "Inputs for next agent" "core handoff contract extension"
assert_file_contains ".github/AGENTS.md" "Decision status" "decision status field"
assert_file_contains ".github/AGENTS.md" "overlay-only" "overlay-only orchestration wording"
assert_file_contains ".github/AGENTS.md" "prompt-level contract" "prompt-level approval caveat in the agent catalog"
assert_file_contains ".github/AGENTS.md" "supervisor-orchestration.md" "supervisor runbook pointer from the agent catalog"

assert_file_contains "docs/runbooks/agentic-dev.md" "Supervisor delegation flow" "supervisor delegation flow guidance"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "orchestration-policy.json" "canonical policy reference"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "Prompt-level contract, not enforcement" "prompt-level contract caveat heading"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "guided delegation plan" "fallback documentation"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "jsonschema|ajv-cli" "schema validation note"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "negative fixtures" "negative fixture coverage note"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "delegation-supervisor" "ADR supervisor naming"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "orchestration-policy.json" "ADR canonical policy source"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "Option C" "ADR deferred option record"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "Enablement Preconditions" "enablement precondition section"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "preToolUse" "hook-inheritance precondition in the runbook"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "preToolUse" "hook-inheritance precondition in the ADR"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "derived tier is non-empty" "non-empty tier assertion in the runbook"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "derived tier is non-empty" "non-empty tier assertion in the ADR"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "requires the validator to accept the result" "tolerated-state positive fixture note in the runbook"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "requires the validator to accept the result" "tolerated-state positive fixture note in the ADR"
assert_file_contains ".github/scripts/check-starter-workflow.sh" "check-supervisor-orchestration.sh" "Bash workflow entry point registration"
assert_file_contains ".github/scripts/check-starter-workflow.ps1" "check-supervisor-orchestration.ps1" "PowerShell workflow entry point registration"
assert_file_contains ".github/scripts/check-agent-contracts.sh" "delegation-supervisor.agent.md" "Bash agent contract registration"
assert_file_contains ".github/scripts/check-agent-contracts.ps1" "delegation-supervisor.agent.md" "PowerShell agent contract registration"

# Fixtures: copy the repository state, mutate one fact, and assert the result. A
# negative fixture requires the validator to reject the mutated state with the
# expected message; a positive fixture requires it to accept a state the runbook
# documents as tolerated. Without these, the checks above can silently degrade
# into no-ops. The recursive run sets SUPERVISOR_SKIP_FIXTURES so the fixtures do
# not re-enter themselves.
apply_fixture_mutation() {
  python3 - "$1" "$2" <<'PY'
import json
import pathlib
import re
import sys

mutation = sys.argv[1]
fixture_root = pathlib.Path(sys.argv[2])


def load(relative_path):
    return json.loads((fixture_root / relative_path).read_text(encoding="utf-8"))


def dump(relative_path, data):
    (fixture_root / relative_path).write_text(
        json.dumps(data, indent=2) + "\n", encoding="utf-8"
    )


def load_allow_list():
    policy_data = load(".github/roles/orchestration-policy.json")
    return set(policy_data.get("specialistAllowList", []))


def derive_non_mutating_tier(allow):
    """Derive the tier exactly as the validator body does: allow-listed agent
    files whose declared capabilities are a subset of read, search, and todo, in
    the sorted order the validator scans them."""
    tier = []
    for agent_path in sorted((fixture_root / ".github/agents").glob("*.agent.md")):
        agent_name = agent_path.name[: -len(".agent.md")]
        if agent_name not in allow:
            continue
        match = re.search(
            r"^tools:\s*\[([^\]]*)\]",
            agent_path.read_text(encoding="utf-8"),
            re.MULTILINE,
        )
        if not match:
            continue
        agent_tools = {item.strip() for item in match.group(1).split(",") if item.strip()}
        if agent_tools <= {"read", "search", "todo"}:
            tier.append((agent_name, agent_path, sorted(agent_tools)))
    return tier


if mutation == "enabled-by-default":
    manifest = load(".github/starter-modules.json")
    for module in manifest.get("modules", []):
        if module.get("id") == "overlay-supervisor-orchestration":
            module["defaultEnabled"] = True
    dump(".github/starter-modules.json", manifest)
elif mutation == "second-delegation-owner":
    access = load(".github/roles/tool-access.json")
    access["agentCapabilityMatrix"]["qa"]["tools"]["delegate-agent"] = True
    dump(".github/roles/tool-access.json", access)
elif mutation == "worker-role-delegation":
    access = load(".github/roles/tool-access.json")
    access["roles"]["review"]["tools"].append("delegate-agent")
    dump(".github/roles/tool-access.json", access)
elif mutation == "frontmatter-divergence":
    agent_path = fixture_root / ".github/agents/delegation-supervisor.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^tools:\s*\[[^\]]*\]",
            "tools: [read, search, todo, edit]",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "write-delegation-without-write-set":
    example_path = ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json"
    example = load(example_path)
    for delegation in example.get("delegations", []):
        if delegation.get("capability") == "write":
            delegation.pop("writeSet", None)
    dump(example_path, example)
elif mutation == "unbounded-write-set":
    example_path = ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json"
    example = load(example_path)
    for delegation in example.get("delegations", []):
        if delegation.get("capability") == "write":
            delegation["writeSet"] = ["TBD"]
            break
    dump(example_path, example)
elif mutation == "enforcement-overclaim":
    agents_path = fixture_root / ".github/AGENTS.md"
    agents_text = agents_path.read_text(encoding="utf-8")
    agents_path.write_text(
        re.sub(
            r"high-risk approval gate that is a prompt-level contract, not enforcement",
            "high-risk approval enforcement",
            agents_text,
            count=1,
        ),
        encoding="utf-8",
    )

elif mutation == "worker-frontmatter-delegation":
    agent_path = fixture_root / ".github/agents/qa.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^tools:\s*\[[^\]]*\]",
            "tools: [read, search, execute, todo, delegate-agent]",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "unregistered-delegation-holder":
    (fixture_root / ".github/agents/rogue-worker.agent.md").write_text(
        "---\n"
        'description: "Fixture agent that declares delegation without a capability-matrix entry."\n'
        "tools: [read, search, todo, delegate-agent]\n"
        "user-invocable: false\n"
        "---\n"
        "Fixture agent used to prove the frontmatter scan catches an agent file\n"
        "that escapes the capability matrix entirely.\n",
        encoding="utf-8",
    )
elif mutation == "allow-list-delegation-holder":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    allow_list_mutated = sorted(
        set(policy_data.get("specialistAllowList", [])) | {"delegation-supervisor"}
    )
    policy_data["specialistAllowList"] = allow_list_mutated
    dump(policy_path, policy_data)
elif mutation == "frontmatter-matrix-mismatch":
    agent_path = fixture_root / ".github/agents/qa.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^tools:\s*\[[^\]]*\]",
            "tools: [read, search, todo]",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "role-hint-mismatch":
    access = load(".github/roles/tool-access.json")
    access["agentRoleHints"]["qa"] = "review"
    dump(".github/roles/tool-access.json", access)
elif mutation == "matrix-entry-without-agent-file":
    access = load(".github/roles/tool-access.json")
    access["agentCapabilityMatrix"]["ghost-worker"] = {
        "role": "review",
        "scope": "Fixture matrix entry with no matching agent file.",
        "tools": {"read": True, "search": True, "todo": True},
    }
    dump(".github/roles/tool-access.json", access)
elif mutation == "registered-agent-without-tools-list":
    agent_path = fixture_root / ".github/agents/qa.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(r"^tools:\s*\[[^\]]*\]\n", "", agent_text, count=1, flags=re.MULTILINE),
        encoding="utf-8",
    )
elif mutation == "matrix-tool-absent-from-tool-definitions":
    access = load(".github/roles/tool-access.json")
    access["agentCapabilityMatrix"]["qa"]["tools"]["browse-web"] = True
    dump(".github/roles/tool-access.json", access)
elif mutation == "enforcement-wording-in-agent-file":
    agent_path = fixture_root / ".github/agents/delegation-supervisor.agent.md"
    with agent_path.open("a", encoding="utf-8") as handle:
        handle.write("\nThe supervisor enforces the high-risk approval boundary.\n")
elif mutation == "allow-listed-agent-without-matrix-entry":
    # The tolerated state the runbook documents and the tier fixture depends on:
    # the frontmatter scan is authoritative, so an allow-listed agent file with no
    # agentCapabilityMatrix entry is accepted rather than rejected. Pinned by a
    # positive fixture so a later hardening that rejects it goes red instead of
    # silently breaking a documented contract.
    non_mutating = derive_non_mutating_tier(load_allow_list())
    if not non_mutating:
        print(
            "[ERROR] Positive fixture could not be applied: the specialist allow-list "
            "has no non-mutating tier to remove a matrix entry from",
            file=sys.stderr,
        )
        sys.exit(1)

    access = load(".github/roles/tool-access.json")
    if access.get("agentCapabilityMatrix", {}).pop(non_mutating[0][0], None) is None:
        print(
            "[ERROR] Positive fixture could not be applied: "
            f"{non_mutating[0][0]} has no agentCapabilityMatrix entry to remove",
            file=sys.stderr,
        )
        sys.exit(1)

    dump(".github/roles/tool-access.json", access)
elif mutation == "empty-non-mutating-tier":
    # Derive the tier the same way the validator does, then make every member
    # able to mutate state. Where a matrix entry exists, the frontmatter and the
    # entry must move together or the agreement check fires as well; errors
    # accumulate, so the tier diagnostic is still the one asserted on below.
    # An allow-listed agent file with no agentCapabilityMatrix entry is a state
    # the validator accepts and the runbook documents, so the fixture must also
    # survive it: the last member's entry is removed before the loop starts, and
    # that removal is what the self-check below pins.
    non_mutating = derive_non_mutating_tier(load_allow_list())

    access = load(".github/roles/tool-access.json")
    matrix = access.get("agentCapabilityMatrix", {})

    # Pre-removing the last member rather than the first keeps the missing-entry
    # state on a non-zero index for any tier larger than one, so the loop cannot
    # reach it by accident, and it is the sole member when the tier holds exactly
    # one agent. The condition is that the tier is non-empty, not that it holds
    # more than one member: a single-member tier is a legal state, so gating the
    # removal on the tier size would let a governance edit drop it silently and
    # return this fixture to the unexercised state it exists to prevent.
    if non_mutating:
        matrix.pop(non_mutating[-1][0], None)

    entries_seen_missing = 0
    for agent_name, agent_path, agent_tools in non_mutating:
        matrix_entry = matrix.get(agent_name)
        if matrix_entry is None:
            entries_seen_missing += 1
        else:
            matrix_entry.setdefault("tools", {})["edit"] = True
        agent_path.write_text(
            re.sub(
                r"^tools:\s*\[[^\]]*\]",
                f"tools: [{', '.join(agent_tools + ['edit'])}]",
                agent_path.read_text(encoding="utf-8"),
                count=1,
                flags=re.MULTILINE,
            ),
            encoding="utf-8",
        )

    # The fixture is only meaningful if the mutation actually reached the
    # missing-entry state. Without this, dropping the pre-removal above would
    # silently return the fixture to a state where the missing-entry branch is
    # never exercised and the fixture still passes, which is the defect this
    # fixture guards. The check is unconditional: it holds for every non-empty
    # tier size, a single-member tier included.
    if entries_seen_missing == 0:
        print(
            "[ERROR] Negative fixture could not be applied: the mutation loop never "
            "observed an allow-listed tier member without an agentCapabilityMatrix entry, "
            "so the missing-entry path is unexercised",
            file=sys.stderr,
        )
        sys.exit(1)

    dump(".github/roles/tool-access.json", access)
else:
    print(f"[ERROR] Unknown fixture mutation: {mutation}", file=sys.stderr)
    sys.exit(1)
PY
}

copy_fixture_root() {
  local target="$1"
  mkdir -p "${target}"
  cp -R "${REPO_ROOT}/.github" "${target}/.github"
  cp -R "${REPO_ROOT}/docs" "${target}/docs"
  # The hook audit log is machine-local state, not repository truth, and no
  # fixture reads it. Prune it before any fixture runs so a fixture copy never
  # carries local audit data.
  rm -rf "${target}/.github/hooks/logs"
}

run_negative_fixture() {
  local mutation="$1"
  local description="$2"
  local expected="$3"
  local fixture_root output
  fixture_root="$(mktemp -d)"

  # A setup or mutation failure must be reported as a fixture error rather than
  # aborting the validator under `set -e`, which would skip every remaining
  # fixture and leak the copy. Report and clean up instead.
  if ! copy_fixture_root "${fixture_root}"; then
    report_error "Negative fixture setup failed: ${description}"
    rm -rf "${fixture_root}"
    return
  fi
  if ! apply_fixture_mutation "${mutation}" "${fixture_root}"; then
    report_error "Negative fixture could not be applied: ${description}"
    rm -rf "${fixture_root}"
    return
  fi

  if output="$(SUPERVISOR_SKIP_FIXTURES=1 bash "${SCRIPT_DIR}/check-supervisor-orchestration.sh" "${fixture_root}" 2>&1)"; then
    report_error "Negative fixture not detected: ${description}"
  elif [[ "${output}" != *"${expected}"* ]]; then
    report_error "Negative fixture failed for the wrong reason: ${description}"
  fi

  rm -rf "${fixture_root}"
}

# The counterpart contract: some repository states are documented as tolerated
# rather than rejected, so they need a fixture too. It asserts acceptance of an
# allow-listed agent file with no agentCapabilityMatrix entry, which the tier
# fixture relies on and no negative fixture can cover.
run_positive_fixture() {
  local mutation="$1"
  local description="$2"
  local fixture_root output
  fixture_root="$(mktemp -d)"

  # Same setup contract as the negative fixtures: a setup or mutation failure is
  # reported rather than aborting the validator under `set -e`, and the copy is
  # removed on every path.
  if ! copy_fixture_root "${fixture_root}"; then
    report_error "Positive fixture setup failed: ${description}"
    rm -rf "${fixture_root}"
    return
  fi
  if ! apply_fixture_mutation "${mutation}" "${fixture_root}"; then
    report_error "Positive fixture could not be applied: ${description}"
    rm -rf "${fixture_root}"
    return
  fi

  if ! output="$(SUPERVISOR_SKIP_FIXTURES=1 bash "${SCRIPT_DIR}/check-supervisor-orchestration.sh" "${fixture_root}" 2>&1)"; then
    report_error "Positive fixture rejected an accepted state: ${description}"
    printf '%s\n' "${output}" >&2
  fi

  rm -rf "${fixture_root}"
}

if [[ "${SUPERVISOR_SKIP_FIXTURES:-0}" != "1" ]]; then
  baseline_root="$(mktemp -d)"
  copy_fixture_root "${baseline_root}"
  if ! SUPERVISOR_SKIP_FIXTURES=1 bash "${SCRIPT_DIR}/check-supervisor-orchestration.sh" "${baseline_root}" >/dev/null 2>&1; then
    report_error "Negative fixture baseline failed: the copied repository state does not pass the validator"
  fi
  rm -rf "${baseline_root}"

  run_negative_fixture "enabled-by-default" "the overlay is enabled by default (defaultEnabled != false)" "must be default-disabled"
  run_negative_fixture "second-delegation-owner" "a capability-matrix entry for an agent other than the supervisor declares delegate-agent" "only delegation-supervisor may hold delegate-agent"
  run_negative_fixture "worker-role-delegation" "a second role declares delegate-agent" "only the orchestration role may hold delegate-agent"
  run_negative_fixture "frontmatter-divergence" "the supervisor frontmatter diverges from the orchestration role" "frontmatter tools must be exactly"
  run_negative_fixture "write-delegation-without-write-set" "a write delegation omits its declared write set" "missing required property 'writeSet'"
  run_negative_fixture "unbounded-write-set" "a write delegation declares an unbounded write set" "declares an unbounded indicator"
  run_negative_fixture "enforcement-overclaim" "the agent catalog describes the approval gate as enforcement" "must not describe the supervisor approval gate as enforcement"
  run_negative_fixture "worker-frontmatter-delegation" "a non-supervisor agent file declares delegate-agent in its own frontmatter" "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  run_negative_fixture "unregistered-delegation-holder" "an agent file declares delegate-agent while escaping the capability matrix" "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  run_negative_fixture "allow-list-delegation-holder" "the specialist allow-list lists a delegation-capable agent" "specialist allow-list must not list the delegation-capable agent"
  run_negative_fixture "frontmatter-matrix-mismatch" "an agent's frontmatter tools diverge from its capability-matrix entry" "frontmatter tools do not match agentCapabilityMatrix tools"
  run_negative_fixture "role-hint-mismatch" "an agentRoleHints entry disagrees with the capability-matrix role" "agentRoleHints entry disagrees with agentCapabilityMatrix role"
  run_negative_fixture "matrix-entry-without-agent-file" "a capability-matrix entry has no agent file" "agentCapabilityMatrix entry has no agent file"
  run_negative_fixture "registered-agent-without-tools-list" "a registered agent file declares no tools frontmatter list" "declares no tools frontmatter list"
  run_negative_fixture "matrix-tool-absent-from-tool-definitions" "a capability-matrix entry enables a tool absent from toolDefinitions" "absent from toolDefinitions"
  run_negative_fixture "enforcement-wording-in-agent-file" "an agent file describes the approval gate as enforcement" "must not describe the supervisor approval gate as enforcement"
  run_negative_fixture "empty-non-mutating-tier" "every allow-listed agent gains a mutating capability, emptying the non-mutating tier" "specialist allow-list has no non-mutating tier"
  run_positive_fixture "allow-listed-agent-without-matrix-entry" "an allow-listed non-mutating agent file has no agentCapabilityMatrix entry"
else
  # SEC-1: never let a fixture-suite bypass pass unannounced. This mode is used by
  # the fixture re-entry child, but any wrapper, Makefile target, or CI `env:` block
  # can set it, so the skip is surfaced instead of silently zeroing the assertions.
  echo "[NOTICE] SUPERVISOR_SKIP_FIXTURES=1 is set: the fixture suite was skipped, so this run asserted only the static checks." >&2
fi

if [[ "${FAILED}" -ne 0 ]]; then
  exit 1
fi

echo "Supervisor orchestration overlay check passed."
