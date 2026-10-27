#!/usr/bin/env bash
# Fixture machinery for check-supervisor-orchestration.sh.
# Sourced by the validator so the invariant body stays readable.
# Requires report_error, SCRIPT_DIR, and REPO_ROOT from the caller.

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
    agents_path = fixture_root / ".github/agent-catalog.md"
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
elif mutation == "worker-agent-tool-delegation":
    agent_path = fixture_root / ".github/agents/qa.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^tools:\s*\[[^\]]*\]",
            "tools: [read, search, execute, todo, agent]",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "worker-agents-key-delegation":
    agent_path = fixture_root / ".github/agents/qa.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^(tools:\s*\[[^\]]*\]\n)",
            r"\1agents: ['senior-software-engineer']\n",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "supervisor-agents-key-off-allow-list":
    agent_path = fixture_root / ".github/agents/delegation-supervisor.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^(tools:\s*\[[^\]]*\]\n)",
            r"\1agents: ['fixture-off-allow-list-agent']\n",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "worker-block-style-tools-delegation":
    agent_path = fixture_root / ".github/agents/qa.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^tools:\s*\[[^\]]*\]",
            "tools:\n  - read\n  - search\n  - execute\n  - todo\n  - agent",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "worker-block-style-agents-key-delegation":
    agent_path = fixture_root / ".github/agents/qa.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^(tools:\s*\[[^\]]*\]\n)",
            r"\1agents:\n  - senior-software-engineer\n",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "supervisor-agents-without-host-tool":
    agent_path = fixture_root / ".github/agents/delegation-supervisor.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^tools:\s*\[[^\]]*\]",
            "tools: [read, search, todo, delegate-agent]",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "supervisor-host-tool-without-agents":
    agent_path = fixture_root / ".github/agents/delegation-supervisor.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^agents:\s*\[[^\]]*\]\r?\n",
            "",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "adapter-mutating-capability":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    adapters = policy_data.get("delegationDepth", {}).get("hostAdapters", {})
    if not adapters:
        print(
            "[ERROR] Negative fixture could not be applied: hostAdapters is empty",
            file=sys.stderr,
        )
        sys.exit(1)
    first_host = next(iter(adapters))
    adapters[first_host].setdefault("delegationTools", []).append("edit")
    dump(policy_path, policy_data)
elif mutation == "supervisor-frontmatter-extra-tool":
    agent_path = fixture_root / ".github/agents/delegation-supervisor.agent.md"
    agent_text = agent_path.read_text(encoding="utf-8")
    agent_path.write_text(
        re.sub(
            r"^tools:\s*\[[^\]]*\]",
            "tools: [read, search, todo, delegate-agent, agent, spawn-agent]",
            agent_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )
elif mutation == "non-allow-listed-agent-without-matrix-entry":
    (fixture_root / ".github/agents/rogue-advisor.agent.md").write_text(
        "---\n"
        'description: "Fixture agent off the allow-list with no capability-matrix entry."\n'
        "tools: [read, search, todo]\n"
        "user-invocable: false\n"
        "---\n"
        "Fixture agent used to prove the registration rule rejects an agent file\n"
        "that is not on the specialist allow-list and has no matrix entry.\n",
        encoding="utf-8",
    )
elif mutation == "non-allow-listed-agent-without-role-hint":
    (fixture_root / ".github/agents/rogue-advisor.agent.md").write_text(
        "---\n"
        'description: "Fixture agent off the allow-list with no role hint."\n'
        "tools: [read, search, todo]\n"
        "user-invocable: false\n"
        "---\n"
        "Fixture agent used to prove the registration rule rejects an agent file\n"
        "that is not on the specialist allow-list and has no role hint.\n",
        encoding="utf-8",
    )
    access = load(".github/roles/tool-access.json")
    access["agentCapabilityMatrix"]["rogue-advisor"] = {
        "role": "review",
        "scope": "Fixture matrix entry for an agent file with no role hint.",
        "tools": {"read": True, "search": True, "todo": True},
    }
    dump(".github/roles/tool-access.json", access)
elif mutation == "unsupported-host-empty-adapter-list":
    # The accepted representation for a host with no verified delegation
    # primitive: an adapter entry with an empty delegationTools list. Pinned by
    # a positive fixture so one twin cannot start rejecting it without a check
    # going red on both platforms.
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data["delegationDepth"]["hostAdapters"]["cursor"] = {
        "delegationTools": [],
        "note": "Fixture host with no verified delegation primitive, recorded as an empty tool list.",
    }
    dump(policy_path, policy_data)
elif mutation == "adapter-enabled-in-capability-matrix":
    access = load(".github/roles/tool-access.json")
    access["agentCapabilityMatrix"]["orchestration-coordinator"]["tools"]["agent"] = True
    dump(".github/roles/tool-access.json", access)
elif mutation == "adapter-case-variant-tool-name":
    # The mutating-name guard matches case-sensitively, so a case variant of a
    # mutating name is a distinct host tool name and is accepted. Pinned by a
    # positive fixture so one twin cannot drift to a case-insensitive match
    # that would reject this state without a check going red on both platforms.
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    adapters = policy_data["delegationDepth"]["hostAdapters"]
    if not adapters:
        print(
            "[ERROR] Positive fixture could not be applied: hostAdapters is empty",
            file=sys.stderr,
        )
        sys.exit(1)
    first_host = next(iter(adapters))
    adapters[first_host].setdefault("delegationTools", []).append("EDIT")
    dump(policy_path, policy_data)
elif mutation == "removed-task-class":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    classes = policy_data.get("taskClasses", [])
    if not any(entry.get("id") == "QUESTION" for entry in classes):
        print(
            "[ERROR] Negative fixture could not be applied: taskClasses has no QUESTION entry to remove",
            file=sys.stderr,
        )
        sys.exit(1)
    policy_data["taskClasses"] = [
        entry for entry in classes if entry.get("id") != "QUESTION"
    ]
    policy_data.get("playbooks", {}).pop("QUESTION", None)
    dump(policy_path, policy_data)
elif mutation == "empty-playbook":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    playbooks = policy_data.get("playbooks", {})
    if "DOCUMENTATION" not in playbooks:
        print(
            "[ERROR] Negative fixture could not be applied: playbooks has no DOCUMENTATION playbook to empty",
            file=sys.stderr,
        )
        sys.exit(1)
    playbooks["DOCUMENTATION"] = []
    dump(policy_path, policy_data)
elif mutation == "playbook-stage-off-allow-list":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    stages = policy_data.get("playbooks", {}).get("QUESTION")
    if not stages:
        print(
            "[ERROR] Negative fixture could not be applied: playbooks has no QUESTION stages to mutate",
            file=sys.stderr,
        )
        sys.exit(1)
    stages[0]["delegatesTo"] = ["rogue-agent"]
    dump(policy_path, policy_data)
elif mutation == "playbook-stage-both-delegation-and-approval":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    stages = policy_data.get("playbooks", {}).get("QUESTION")
    if not stages:
        print(
            "[ERROR] Negative fixture could not be applied: playbooks has no QUESTION stages to mutate",
            file=sys.stderr,
        )
        sys.exit(1)
    stages[1]["requiresHumanApproval"] = True
    dump(policy_path, policy_data)
elif mutation == "playbook-unknown-class-id":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("playbooks", {})["GHOST_CLASS"] = [
        {
            "id": "ghost-stage",
            "name": "Ghost stage",
            "delegatesTo": ["analyst"],
            "skipRequiresReason": True,
        }
    ]
    dump(policy_path, policy_data)
elif mutation == "mutated-evidence-vocabulary":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("evidenceRequirements", {})["resultVocabulary"] = [
        "VERIFIED",
        "NOT_VERIFIED",
        "MAYBE",
    ]
    dump(policy_path, policy_data)
elif mutation == "unknown-evidence-surface":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("evidenceRequirements", {}).setdefault("surfaces", {})[
        "network"
    ] = {"evidence": ["ping-the-service"]}
    dump(policy_path, policy_data)
elif mutation == "edited-completion-rule":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("evidenceRequirements", {})[
        "completionRule"
    ] = "agent-declared-after-self-report"
    dump(policy_path, policy_data)
elif mutation == "complexity-default-not-complex":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("complexityRouting", {})["defaultWhenUncertain"] = "simple"
    dump(policy_path, policy_data)
elif mutation == "complexity-empty-simple-workflow":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("complexityRouting", {})["simpleWorkflow"] = ""
    dump(policy_path, policy_data)
elif mutation == "complexity-empty-complex-workflow":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("complexityRouting", {})["complexWorkflow"] = ""
    dump(policy_path, policy_data)
elif mutation == "complexity-empty-complexIfAny":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("complexityRouting", {})["complexIfAny"] = []
    dump(policy_path, policy_data)
elif mutation == "complexity-empty-notBasedOn":
    policy_path = ".github/roles/orchestration-policy.json"
    policy_data = load(policy_path)
    policy_data.setdefault("complexityRouting", {})["notBasedOn"] = []
    dump(policy_path, policy_data)
elif mutation == "malformed-delegation-result":
    result_path = ".github/examples/supervisor-orchestration/simple-bugfix-delegation-result.json"
    result_data = load(result_path)
    if "verificationPerformed" not in result_data:
        print(
            "[ERROR] Negative fixture could not be applied: delegation-result example has no "
            "verificationPerformed to remove",
            file=sys.stderr,
        )
        sys.exit(1)
    result_data.pop("verificationPerformed")
    dump(result_path, result_data)
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

