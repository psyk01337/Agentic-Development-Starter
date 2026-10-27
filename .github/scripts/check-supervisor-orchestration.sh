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
  ".github/skills/verification-evidence-loop/SKILL.md"
  ".github/skills/adversarial-review/SKILL.md"
  ".github/skills/arena-bakeoff/SKILL.md"
  ".github/skills/swarm/SKILL.md"
  ".github/skills/prose-cleanup/SKILL.md"
  ".github/skills/session-compaction/SKILL.md"
  ".github/skills/decision-trail/SKILL.md"
  ".github/roles/orchestration-policy.json"
  ".github/schema/delegation-plan.schema.json"
  ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json"
  ".github/schema/delegation-result.schema.json"
  ".github/examples/supervisor-orchestration/simple-bugfix-delegation-result.json"
  ".github/scripts/check-supervisor-orchestration.ps1"
  ".github/scripts/check-supervisor-orchestration.sh"
  ".github/scripts/lib/supervisor-fixtures.sh"
  ".github/scripts/lib/supervisor-fixtures.ps1"
  "docs/runbooks/supervisor-orchestration.md"
  "docs/runbooks/engineering-team.md"
  "docs/runbooks/agentic-engine.md"
  ".github/skills/repair-loop/SKILL.md"
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

# The host adapter map is the canonical source for the platform delegation
# vocabulary. The rule below derives the tool names it guards from this map
# rather than from a hardcoded list, so adding a host is a data change. The
# map is closed on two sides: it must not be empty, and no adapter name may
# resolve to a mutating capability, or the map becomes a laundering route for
# privileged tool names.
host_adapters = depth.get("hostAdapters", {})
adapter_tools = set()
if not isinstance(host_adapters, dict) or not host_adapters:
    errors.append(
        "orchestration-policy.json must define a non-empty delegationDepth.hostAdapters map"
    )
for host_name, adapter in host_adapters.items():
    if not isinstance(adapter, dict):
        errors.append(
            f"orchestration-policy.json hostAdapters entry for {host_name} must be an object"
        )
        continue
    declared = adapter.get("delegationTools")
    if not isinstance(declared, list):
        errors.append(
            f"orchestration-policy.json hostAdapters entry for {host_name} "
            "must declare a delegationTools list"
        )
        continue
    adapter_tools.update(declared)
if not adapter_tools:
    errors.append(
        "orchestration-policy.json hostAdapters must declare at least one delegation tool name"
    )
for adapter_tool in sorted(adapter_tools):
    if adapter_tool in ("edit", "execute"):
        errors.append(
            "orchestration-policy.json hostAdapters must not map delegation to a "
            f"mutating capability: {adapter_tool}"
        )

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

# ADR 0005 routing data. taskClasses owns playbook selection and is a closed,
# ordered thirteen-class taxonomy; complexityRouting owns the simple/complex
# escalation envelope and is pinned on its own; evidenceRequirements owns the
# fixed result vocabulary, the completion rule, and the closed surface set.
# None of these three keys was read by any check before ADR 0005 rollout slice 3.
expected_classes = [
    "QUESTION",
    "INVESTIGATION",
    "BUG_FIX",
    "FEATURE",
    "REFACTOR",
    "ARCHITECTURE",
    "SECURITY",
    "PERFORMANCE",
    "TESTING",
    "DOCUMENTATION",
    "MIGRATION",
    "INFRASTRUCTURE",
    "UNKNOWN_COMPLEX",
]
task_classes = policy.get("taskClasses")
class_ids = []
if not isinstance(task_classes, list) or not task_classes:
    errors.append("orchestration-policy.json taskClasses must be a non-empty list")
else:
    for entry in task_classes:
        if not isinstance(entry, dict):
            errors.append("orchestration-policy.json taskClasses entries must be objects")
            continue
        class_id = entry.get("id")
        if not isinstance(class_id, str) or not class_id:
            errors.append("orchestration-policy.json taskClasses entries must declare a non-empty id")
            continue
        class_ids.append(class_id)
        if not isinstance(entry.get("description"), str) or not entry["description"].strip():
            errors.append(
                f"orchestration-policy.json taskClasses entry {class_id} must declare a non-empty description"
            )
    missing_classes = [class_id for class_id in expected_classes if class_id not in class_ids]
    extra_classes = [class_id for class_id in class_ids if class_id not in expected_classes]
    duplicated_classes = sorted({class_id for class_id in class_ids if class_ids.count(class_id) > 1})
    if missing_classes:
        errors.append(f"orchestration-policy.json taskClasses are missing {', '.join(missing_classes)}")
    if extra_classes:
        errors.append(
            f"orchestration-policy.json taskClasses contain unknown classes: {', '.join(extra_classes)}"
        )
    if duplicated_classes:
        errors.append(
            f"orchestration-policy.json taskClasses repeat classes: {', '.join(duplicated_classes)}"
        )
    if not missing_classes and not extra_classes and not duplicated_classes:
        if class_ids != expected_classes:
            errors.append(
                "orchestration-policy.json taskClasses must preserve the ordered thirteen-class taxonomy"
            )

playbooks = policy.get("playbooks")
allowed_delegates = set(allow_list) | {"delegation-supervisor"}
if not isinstance(playbooks, dict):
    errors.append("orchestration-policy.json playbooks must be an object")
else:
    unknown_class_ids = sorted(set(playbooks) - set(expected_classes))
    if unknown_class_ids:
        errors.append(
            "orchestration-policy.json playbooks references an unknown class id: "
            f"{', '.join(unknown_class_ids)}"
        )
    for class_id in expected_classes:
        if class_id not in playbooks:
            errors.append(f"orchestration-policy.json playbooks is missing a playbook for class {class_id}")
    for class_id, stages in playbooks.items():
        if not isinstance(stages, list) or not stages:
            errors.append(f"orchestration-policy.json playbook for {class_id} is empty")
            continue
        for index, stage in enumerate(stages):
            if not isinstance(stage, dict):
                errors.append(
                    f"orchestration-policy.json playbook stage {class_id}[{index}] must be an object"
                )
                continue
            stage_id = stage.get("id")
            if not isinstance(stage_id, str) or not stage_id:
                errors.append(
                    f"orchestration-policy.json playbook stage {class_id}[{index}] must declare a non-empty id"
                )
            if not isinstance(stage.get("name"), str) or not stage["name"].strip():
                errors.append(
                    f"orchestration-policy.json playbook stage {class_id}[{index}] must declare a non-empty name"
                )
            if stage.get("skipRequiresReason") is not True:
                errors.append(
                    f"orchestration-policy.json playbook stage {class_id}[{index}] "
                    "must set skipRequiresReason to true"
                )
            delegates = stage.get("delegatesTo")
            if not isinstance(delegates, list):
                errors.append(
                    f"orchestration-policy.json playbook stage {class_id}[{index}] "
                    "must declare delegatesTo as a list"
                )
                delegates_nonempty = False
                delegates = []
            else:
                delegates_nonempty = len(delegates) > 0
            human_approval = stage.get("requiresHumanApproval") is True
            if delegates_nonempty == human_approval:
                errors.append(
                    f"orchestration-policy.json playbook stage {class_id}[{index}] must set exactly one "
                    "of a non-empty delegatesTo and requiresHumanApproval: true"
                )
            for delegate_name in delegates:
                if delegate_name not in allowed_delegates:
                    errors.append(
                        f"orchestration-policy.json playbook stage {class_id}[{index}] delegates to an "
                        f"agent outside the allow-list: {delegate_name}"
                    )

evidence = policy.get("evidenceRequirements")
expected_surfaces = ["ui", "api", "database", "cli", "configuration", "library"]
if not isinstance(evidence, dict):
    errors.append("orchestration-policy.json evidenceRequirements must be an object")
else:
    if evidence.get("resultVocabulary") != ["VERIFIED", "NOT_VERIFIED", "INCONCLUSIVE"]:
        errors.append(
            "orchestration-policy.json evidenceRequirements.resultVocabulary must be exactly "
            "[VERIFIED, NOT_VERIFIED, INCONCLUSIVE]"
        )
    if evidence.get("inconclusiveNeverSuccess") is not True:
        errors.append(
            "orchestration-policy.json evidenceRequirements.inconclusiveNeverSuccess must be true"
        )
    if evidence.get("completionRule") != "orchestrator-declared-after-verification-evidence":
        errors.append(
            "orchestration-policy.json evidenceRequirements.completionRule must be "
            "'orchestrator-declared-after-verification-evidence'"
        )
    surfaces = evidence.get("surfaces")
    if not isinstance(surfaces, dict):
        errors.append("orchestration-policy.json evidenceRequirements.surfaces must be an object")
    else:
        unknown_surfaces = sorted(set(surfaces) - set(expected_surfaces))
        if unknown_surfaces:
            errors.append(
                "orchestration-policy.json evidenceRequirements.surfaces contains an "
                f"unknown surface: {', '.join(unknown_surfaces)}"
            )
        for surface_id in expected_surfaces:
            if surface_id not in surfaces:
                errors.append(
                    f"orchestration-policy.json evidenceRequirements.surfaces is missing {surface_id}"
                )
        for surface_id, surface in surfaces.items():
            if surface_id not in expected_surfaces:
                continue
            evidence_list = surface.get("evidence") if isinstance(surface, dict) else None
            if not isinstance(evidence_list, list) or not evidence_list:
                errors.append(
                    f"orchestration-policy.json evidenceRequirements surface {surface_id} "
                    "must declare a non-empty evidence list"
                )
                continue
            if any(not isinstance(item, str) or not item.strip() for item in evidence_list):
                errors.append(
                    f"orchestration-policy.json evidenceRequirements surface {surface_id} "
                    "must declare non-empty string evidence kinds"
                )

# The complexityRouting pins promised by ADR 0005 rollout step 3. The key
# shipped as unread data since v1.0; these checks make it data again.
complexity = policy.get("complexityRouting", {})
if complexity.get("defaultWhenUncertain") != "complex":
    errors.append("orchestration-policy.json complexityRouting.defaultWhenUncertain must be 'complex'")
if not isinstance(complexity.get("simpleWorkflow"), str) or not complexity["simpleWorkflow"].strip():
    errors.append("orchestration-policy.json complexityRouting.simpleWorkflow must be a non-empty string")
if not isinstance(complexity.get("complexWorkflow"), str) or not complexity["complexWorkflow"].strip():
    errors.append("orchestration-policy.json complexityRouting.complexWorkflow must be a non-empty string")
if not isinstance(complexity.get("complexIfAny"), list) or not complexity["complexIfAny"]:
    errors.append("orchestration-policy.json complexityRouting.complexIfAny must be a non-empty list")
if not isinstance(complexity.get("notBasedOn"), list) or not complexity["notBasedOn"]:
    errors.append("orchestration-policy.json complexityRouting.notBasedOn must be a non-empty list")

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

# ADR 0006 result contract: the worked example must validate, and the schema's
# enums must resolve against the canonical policy data rather than carry a
# second copy of the allow-list, the result vocabulary, or the surface set.
result_schema = load(".github/schema/delegation-result.schema.json")
result_example = load(".github/examples/supervisor-orchestration/simple-bugfix-delegation-result.json")
errors.extend(validate_instance(result_example, result_schema))
result_agent_enum = result_schema.get("properties", {}).get("agent", {}).get("enum", [])
if sorted(result_agent_enum) != sorted(allow_list):
    errors.append(
        "delegation-result.schema.json agent enum has drifted from the canonical policy allow-list"
    )
result_vocabulary_enum = (
    result_schema.get("properties", {})
    .get("verificationPerformed", {})
    .get("items", {})
    .get("properties", {})
    .get("result", {})
    .get("enum", [])
)
if result_vocabulary_enum != policy.get("evidenceRequirements", {}).get("resultVocabulary"):
    errors.append(
        "delegation-result.schema.json result enum has drifted from the canonical evidence vocabulary"
    )
result_surface_enum = (
    result_schema.get("properties", {})
    .get("verificationPerformed", {})
    .get("items", {})
    .get("properties", {})
    .get("surface", {})
    .get("enum", [])
)
policy_surfaces = list(policy.get("evidenceRequirements", {}).get("surfaces", {}) or {})
if sorted(result_surface_enum) != sorted(policy_surfaces):
    errors.append(
        "delegation-result.schema.json surface enum has drifted from the canonical evidence surfaces"
    )

# Sole-holder invariant, checked over every agent file rather than only the
# capability matrix. A new agent file can appear without a matrix entry, so the
# frontmatter scan is the authoritative path and the matrix must then agree with
# it, in both directions.
agents_dir = root / ".github/agents"
agent_files = sorted(agents_dir.glob("*.agent.md"))
if not agent_files:
    errors.append("No agent files found under .github/agents")

def parse_frontmatter_list(agent_text, key):
    """Return the declared item set for a frontmatter list key, or None when the
    key is absent. Both the inline form (`key: [a, b]`) and the block form
    (`key:` followed by indented `- item` lines) are read, because the platform
    accepts either and a rule that reads only the inline form can be bypassed by
    reformatting the same declaration."""
    inline = re.search(rf"^{key}:\s*\[([^\]]*)\]", agent_text, re.MULTILINE)
    if inline:
        return {
            item.strip().strip("'\"")
            for item in inline.group(1).split(",")
            if item.strip().strip("'\"")
        }
    block = re.search(
        rf"^{key}:\s*\r?\n((?:[ \t]+-[^\r\n]*\r?\n?)+)",
        agent_text,
        re.MULTILINE,
    )
    if not block:
        return None
    items = set()
    for line in block.group(1).splitlines():
        item = line.strip()
        if not item.startswith("-"):
            continue
        item = item[1:].strip().strip("'\"")
        if item:
            items.add(item)
    return items


frontmatter_tools = {}
agents_without_tools_list = set()
for agent_path in agent_files:
    agent_name = agent_path.name[: -len(".agent.md")]
    agent_text = agent_path.read_text(encoding="utf-8")
    parsed_tools = parse_frontmatter_list(agent_text, "tools")
    if parsed_tools is None:
        # tools: is optional in .agent.md frontmatter, so an unregistered agent
        # file is not required to declare one. Only a registered capability
        # boundary makes the list load-bearing.
        agents_without_tools_list.add(agent_name)
        continue
    frontmatter_tools[agent_name] = parsed_tools

supervisor_tools = frontmatter_tools.get("delegation-supervisor")
if supervisor_tools is not None:
    if "delegate-agent" not in supervisor_tools:
        errors.append(
            "delegation-supervisor frontmatter must declare the delegate-agent capability"
        )
    missing_role_tools = sorted(expected_role_tools - supervisor_tools)
    if missing_role_tools:
        errors.append(
            "delegation-supervisor frontmatter tools must include "
            f"{', '.join(missing_role_tools)}"
        )
    # Contains-plus-closed-adapter-allow-list: the holder may declare the
    # canonical capability plus host tool names from the adapter map, and
    # nothing else. The closed side is what keeps this weaker shape safe.
    extra_tools = sorted(supervisor_tools - expected_role_tools - adapter_tools)
    if extra_tools:
        errors.append(
            "delegation-supervisor frontmatter declares tools outside the orchestration "
            f"role and hostAdapters: {', '.join(extra_tools)}"
        )

for agent_name in sorted(frontmatter_tools):
    if agent_name != "delegation-supervisor" and "delegate-agent" in frontmatter_tools[agent_name]:
        errors.append(
            "only delegation-supervisor may declare delegate-agent in agent frontmatter; "
            f"found in {agent_name}"
        )

# The same invariant over the host's own vocabulary. The repository names the
# capability `delegate-agent`, but a runtime expresses delegation with its own
# tool name and an agent allow-list key, so a rule keyed only to the repository's
# name would let a second delegation path in with every check still green.
frontmatter_subagents = {}
# The host vocabulary is derived from the hostAdapters map in
# orchestration-policy.json rather than hardcoded, so a host with a differently
# named primitive is covered by data instead of a code change.
platform_delegation_tools = adapter_tools
for agent_path in agent_files:
    agent_name = agent_path.name[: -len(".agent.md")]
    parsed_subagents = parse_frontmatter_list(
        agent_path.read_text(encoding="utf-8"), "agents"
    )
    if parsed_subagents is None:
        continue
    frontmatter_subagents[agent_name] = parsed_subagents

for agent_name in sorted(frontmatter_tools):
    if agent_name == "delegation-supervisor":
        continue
    platform_declared = sorted(frontmatter_tools[agent_name] & platform_delegation_tools)
    if platform_declared:
        errors.append(
            "only delegation-supervisor may declare a platform delegation tool in agent "
            f"frontmatter; found {', '.join(platform_declared)} in {agent_name}"
        )

for agent_name in sorted(frontmatter_subagents):
    if agent_name != "delegation-supervisor":
        errors.append(
            "only delegation-supervisor may declare an agent allow-list in agent frontmatter; "
            f"found agents: in {agent_name}"
        )

supervisor_subagents = frontmatter_subagents.get("delegation-supervisor")
if supervisor_subagents is not None:
    off_allow_list = sorted(supervisor_subagents - set(allow_list))
    if off_allow_list:
        errors.append(
            "delegation-supervisor agent allow-list must stay within the canonical "
            f"specialistAllowList; found {', '.join(off_allow_list)}"
        )

# Pairing rules: the allow-list and the invocation path exist together or not
# at all. An allow-list nothing can invoke is a guardrail in appearance only,
# and an invocation path with no validated allow-list is the unscoped case.
supervisor_host_tools = (
    sorted(supervisor_tools & platform_delegation_tools)
    if supervisor_tools is not None
    else []
)
supervisor_has_agents_key = "delegation-supervisor" in frontmatter_subagents
if supervisor_has_agents_key and not supervisor_host_tools:
    errors.append(
        "delegation-supervisor declares an agents allow-list without a host "
        "delegation tool from hostAdapters"
    )
if supervisor_host_tools and not supervisor_has_agents_key:
    errors.append(
        "delegation-supervisor declares a host delegation tool without an agents allow-list"
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
    adapter_enabled = sorted(
        tool
        for tool, enabled in matrix_tools.items()
        if enabled is True and tool in platform_delegation_tools
    )
    if adapter_enabled:
        errors.append(
            f"{agent_name} agentCapabilityMatrix must not enable host adapter tools: "
            f"{', '.join(adapter_enabled)} (host tool names live in "
            "orchestration-policy.json hostAdapters)"
        )
    unknown_enabled = sorted(
        tool
        for tool, enabled in matrix_tools.items()
        if enabled is True
        and tool not in tool_definitions
        and tool not in platform_delegation_tools
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
    frontmatter_without_adapters = frontmatter_tools[agent_name] - platform_delegation_tools
    if declared_tools != frontmatter_without_adapters:
        errors.append(
            f"{agent_name} frontmatter tools do not match agentCapabilityMatrix tools: "
            f"frontmatter {', '.join(sorted(frontmatter_without_adapters))}, "
            f"matrix {', '.join(sorted(declared_tools))}"
        )

# Registration direction (ADR 0004 Phase 3): every agent file not on the
# specialist allow-list must carry both a capability-matrix entry and a role
# hint. The tolerance for an allow-listed non-mutating agent with no matrix
# entry stays in place, because the tier derives from frontmatter — a reason
# that exists only for allow-listed agents.
all_agent_names = sorted(agent_path.name[: -len(".agent.md")] for agent_path in agent_files)
for agent_name in all_agent_names:
    if agent_name in allow_list:
        continue
    if agent_name not in matrix:
        errors.append(
            f"{agent_name} agent is not on the specialist allow-list and has no "
            "agentCapabilityMatrix entry"
        )
    if agent_name not in hints:
        errors.append(
            f"{agent_name} agent is not on the specialist allow-list and has no "
            "agentRoleHints entry"
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

governance_files = [".github/agent-catalog.md", ".github/roles/tool-access.json"]
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

assert_file_contains ".github/agent-catalog.md" "delegation-supervisor" "supervisor agent catalog entry"
assert_file_contains ".github/agent-catalog.md" "orchestration-coordinator" "coordinator role distinction"
assert_file_contains ".github/agent-catalog.md" "Inputs for next agent" "core handoff contract extension"
assert_file_contains ".github/agent-catalog.md" "Decision status" "decision status field"
assert_file_contains ".github/agent-catalog.md" "overlay-only" "overlay-only orchestration wording"
assert_file_contains ".github/agent-catalog.md" "prompt-level contract" "prompt-level approval caveat in the agent catalog"
assert_file_contains ".github/agent-catalog.md" "supervisor-orchestration.md" "supervisor runbook pointer from the agent catalog"
assert_file_contains ".github/agent-catalog.md" "Treat a delegated subagent as stateless: it does not inherit the conversation history, cannot ask clarifying questions, and may not have todo or follow-up tools." "delegated subagent statelessness rule"
assert_file_contains ".github/agent-catalog.md" "Return needs-clarification as a terminal result, not as a question that waits for an answer." "delegated needs-clarification terminal rule"
assert_file_contains ".github/agent-catalog.md" "The guided handoff allow-list and the delegable subagent allow-list are different" "guided versus delegable allow-list distinction"
assert_file_contains "docs/runbooks/engineering-team.md" "Treat a delegated subagent as stateless: it does not inherit the conversation history, cannot ask clarifying questions, and may not have todo or follow-up tools." "engineering team runbook statelessness parity"

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
assert_file_contains "docs/runbooks/supervisor-orchestration.md" "hostAdapters" "host adapter map reference in the supervisor runbook"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "Amended by ADR 0004" "ADR 0004 amendment pointer in ADR 0003"
assert_file_contains "docs/runbooks/supervisor-orchestration.md" 'must carry an `agentCapabilityMatrix` entry' "registration rule note in the supervisor runbook"
assert_file_contains "docs/adr/0003-supervisor-orchestration-overlay.md" "Amended by ADR 0004 Phase 3" "ADR 0004 Phase 3 amendment pointer in ADR 0003"
assert_file_contains ".github/skills/verification-evidence-loop/SKILL.md" "delegation-result.schema.json" "verification skill result-contract reference"
assert_file_contains ".github/skills/verification-evidence-loop/SKILL.md" "is never a success" "verification skill inconclusive-never-success rule"
assert_file_contains ".github/skills/adversarial-review/SKILL.md" "SEVERITY, LOCATION, CLAIM, EVIDENCE, FAILURE_SCENARIO, RECOMMENDED_ACTION" "adversarial-review finding-format line"
assert_file_contains ".github/skills/adversarial-review/SKILL.md" "must deduplicate findings" "adversarial-review deduplication rule"
assert_file_contains ".github/skills/adversarial-review/SKILL.md" "Evidence outranks voting" "adversarial-review evidence-outranks-voting rule"
assert_file_contains ".github/skills/arena-bakeoff/SKILL.md" "must not modify the same working tree" "arena-bakeoff candidate isolation rule"
assert_file_contains ".github/skills/arena-bakeoff/SKILL.md" "proposal or implementation, assumptions, tradeoffs, rejected alternatives, verification evidence" "arena-bakeoff five-item candidate return"
assert_file_contains ".github/skills/arena-bakeoff/SKILL.md" "Never average incompatible architectures" "arena-bakeoff never-average rule"
assert_file_contains ".github/skills/swarm/SKILL.md" "solve DIFFERENT independent slices concurrently" "swarm definition rule"
assert_file_contains ".github/skills/swarm/SKILL.md" "Detect shared mutable state before parallel execution" "swarm shared-state detection rule"
assert_file_contains ".github/skills/swarm/SKILL.md" "must not silently overwrite" "swarm no-silent-overwrite rule"
assert_file_contains ".github/skills/swarm/SKILL.md" "Aggregate results only after all required slices finish" "swarm aggregation rule"
assert_file_contains ".github/skills/prose-cleanup/SKILL.md" "This skill is NOT responsible for workflow-state storage" "workflow-state boundary"
assert_file_contains ".github/skills/prose-cleanup/SKILL.md" "Preserve technical detail" "technical-detail preservation"
assert_file_contains ".github/skills/prose-cleanup/SKILL.md" "writing-quality filter, not a context compressor" "writing-quality vs context-compaction boundary"
assert_file_contains ".github/skills/session-compaction/SKILL.md" "Never discard unresolved risk or evidence necessary to continue safely" "session-compaction never-discard-risk rule"
assert_file_contains ".github/skills/session-compaction/SKILL.md" "compact continuation brief" "session-compaction brief phrase"
assert_file_contains ".github/skills/session-compaction/SKILL.md" "Discard conversational filler" "session-compaction discard-filler rule"
assert_file_contains ".github/skills/decision-trail/SKILL.md" "Do NOT confuse decision history with workflow state" "decision-trail workflow-state boundary"
assert_file_contains ".github/skills/decision-trail/SKILL.md" "Prefer pointers over long prose" "decision-trail pointer-over-prose rule"
assert_file_contains ".github/skills/decision-trail/SKILL.md" "For trivial changes, do not create unnecessary logging artifacts" "decision-trail trivial-changes rule"
assert_file_contains ".github/scripts/check-starter-workflow.sh" "check-supervisor-orchestration.sh" "Bash workflow entry point registration"
assert_file_contains ".github/scripts/check-starter-workflow.ps1" "check-supervisor-orchestration.ps1" "PowerShell workflow entry point registration"
assert_file_contains ".github/scripts/check-agent-contracts.sh" "delegation-supervisor.agent.md" "Bash agent contract registration"
assert_file_contains ".github/scripts/check-agent-contracts.ps1" "delegation-supervisor.agent.md" "PowerShell agent contract registration"

# Fixture machinery lives in lib/supervisor-fixtures.sh so the invariant body
# above stays reviewable. Sourced here because it relies on report_error,
# SCRIPT_DIR, and REPO_ROOT.
source "${SCRIPT_DIR}/lib/supervisor-fixtures.sh"

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
  run_negative_fixture "frontmatter-divergence" "the supervisor frontmatter diverges from the orchestration role" "must declare the delegate-agent capability"
  run_negative_fixture "write-delegation-without-write-set" "a write delegation omits its declared write set" "missing required property 'writeSet'"
  run_negative_fixture "unbounded-write-set" "a write delegation declares an unbounded write set" "declares an unbounded indicator"
  run_negative_fixture "enforcement-overclaim" "the agent catalog describes the approval gate as enforcement" "must not describe the supervisor approval gate as enforcement"
  run_negative_fixture "worker-frontmatter-delegation" "a non-supervisor agent file declares delegate-agent in its own frontmatter" "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  run_negative_fixture "unregistered-delegation-holder" "an agent file declares delegate-agent while escaping the capability matrix" "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  run_negative_fixture "worker-agent-tool-delegation" "a non-supervisor agent file declares a platform delegation tool in its own frontmatter" "only delegation-supervisor may declare a platform delegation tool in agent frontmatter"
  run_negative_fixture "worker-agents-key-delegation" "a non-supervisor agent file declares an agent allow-list in its own frontmatter" "only delegation-supervisor may declare an agent allow-list in agent frontmatter"
  run_negative_fixture "supervisor-agents-key-off-allow-list" "the supervisor agent allow-list names an agent outside the canonical allow-list" "agent allow-list must stay within the canonical specialistAllowList"
  run_negative_fixture "supervisor-agents-without-host-tool" "the supervisor declares an agents allow-list without a host delegation tool" "declares an agents allow-list without a host delegation tool"
  run_negative_fixture "supervisor-host-tool-without-agents" "the supervisor declares a host delegation tool without an agents allow-list" "declares a host delegation tool without an agents allow-list"
  run_negative_fixture "adapter-mutating-capability" "the host adapter map declares a tool name that resolves to a mutating capability" "must not map delegation to a mutating capability"
  run_negative_fixture "supervisor-frontmatter-extra-tool" "the supervisor frontmatter declares a tool outside the role and hostAdapters" "outside the orchestration role and hostAdapters"
  run_negative_fixture "non-allow-listed-agent-without-matrix-entry" "an agent file off the allow-list has no agentCapabilityMatrix entry" "is not on the specialist allow-list and has no agentCapabilityMatrix entry"
  run_negative_fixture "non-allow-listed-agent-without-role-hint" "an agent file off the allow-list has no agentRoleHints entry" "is not on the specialist allow-list and has no agentRoleHints entry"
  run_negative_fixture "worker-block-style-tools-delegation" "a non-supervisor agent file declares a platform delegation tool in block-style frontmatter" "only delegation-supervisor may declare a platform delegation tool in agent frontmatter"
  run_negative_fixture "worker-block-style-agents-key-delegation" "a non-supervisor agent file declares a block-style agent allow-list in its own frontmatter" "only delegation-supervisor may declare an agent allow-list in agent frontmatter"
  run_negative_fixture "allow-list-delegation-holder" "the specialist allow-list lists a delegation-capable agent" "specialist allow-list must not list the delegation-capable agent"
  run_negative_fixture "frontmatter-matrix-mismatch" "an agent's frontmatter tools diverge from its capability-matrix entry" "frontmatter tools do not match agentCapabilityMatrix tools"
  run_negative_fixture "role-hint-mismatch" "an agentRoleHints entry disagrees with the capability-matrix role" "agentRoleHints entry disagrees with agentCapabilityMatrix role"
  run_negative_fixture "matrix-entry-without-agent-file" "a capability-matrix entry has no agent file" "agentCapabilityMatrix entry has no agent file"
  run_negative_fixture "registered-agent-without-tools-list" "a registered agent file declares no tools frontmatter list" "declares no tools frontmatter list"
  run_negative_fixture "matrix-tool-absent-from-tool-definitions" "a capability-matrix entry enables a tool absent from toolDefinitions" "absent from toolDefinitions"
  run_negative_fixture "adapter-enabled-in-capability-matrix" "a capability-matrix entry enables a host adapter tool" "agentCapabilityMatrix must not enable host adapter tools"
  run_negative_fixture "enforcement-wording-in-agent-file" "an agent file describes the approval gate as enforcement" "must not describe the supervisor approval gate as enforcement"
  run_negative_fixture "empty-non-mutating-tier" "every allow-listed agent gains a mutating capability, emptying the non-mutating tier" "specialist allow-list has no non-mutating tier"
  run_negative_fixture "removed-task-class" "the policy drops a task class from the taxonomy" "taskClasses are missing QUESTION"
  run_negative_fixture "empty-playbook" "a playbook becomes an empty stage list" "playbook for DOCUMENTATION is empty"
  run_negative_fixture "playbook-stage-off-allow-list" "a playbook stage delegates to an agent outside the allow-list" "delegates to an agent outside the allow-list"
  run_negative_fixture "playbook-stage-both-delegation-and-approval" "a playbook stage sets both a non-empty delegatesTo and requiresHumanApproval" "must set exactly one of a non-empty delegatesTo and requiresHumanApproval"
  run_negative_fixture "playbook-unknown-class-id" "a playbook references an unknown class id" "playbooks references an unknown class id"
  run_negative_fixture "mutated-evidence-vocabulary" "the evidence result vocabulary is mutated" "evidenceRequirements.resultVocabulary"
  run_negative_fixture "unknown-evidence-surface" "an evidence surface outside the closed vocabulary appears" "contains an unknown surface"
  run_negative_fixture "edited-completion-rule" "the completion rule is edited" "evidenceRequirements.completionRule"
  run_negative_fixture "complexity-default-not-complex" "complexityRouting.defaultWhenUncertain changes from complex" "defaultWhenUncertain must be 'complex'"
  run_negative_fixture "complexity-empty-simple-workflow" "complexityRouting.simpleWorkflow becomes empty" "simpleWorkflow must be a non-empty string"
  run_negative_fixture "complexity-empty-complex-workflow" "complexityRouting.complexWorkflow becomes empty" "complexWorkflow must be a non-empty string"
  run_negative_fixture "complexity-empty-complexIfAny" "complexityRouting.complexIfAny becomes empty" "complexIfAny must be a non-empty list"
  run_negative_fixture "complexity-empty-notBasedOn" "complexityRouting.notBasedOn becomes empty" "notBasedOn must be a non-empty list"
  run_negative_fixture "malformed-delegation-result" "a delegation result omits its verification record" "missing required property 'verificationPerformed'"
  run_positive_fixture "allow-listed-agent-without-matrix-entry" "an allow-listed non-mutating agent file has no agentCapabilityMatrix entry"
  run_positive_fixture "unsupported-host-empty-adapter-list" "a host adapter entry records an unsupported host with an empty delegationTools list"
  run_positive_fixture "adapter-case-variant-tool-name" "a case-variant adapter tool name is accepted as a distinct non-mutating host name"
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
