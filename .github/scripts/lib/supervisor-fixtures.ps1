# Fixture machinery for check-supervisor-orchestration.ps1.
# Dot-sourced by the validator so the invariant body stays readable.
# Requires Add-CheckError, $RepoRoot, and $ValidatorPath from the caller.

# Fixtures: copy the repository state, mutate one fact, and assert the result.
# A negative fixture requires the validator to reject the mutated state with the
# expected message; a positive fixture requires it to accept a state the runbook
# documents as tolerated. Without these, the checks above can silently degrade
# into no-ops. Each fixture re-runs this script in a separate pwsh process with
# SUPERVISOR_SKIP_FIXTURES set so the fixtures do not re-enter themselves.
function Copy-FixtureRoot([string]$Target) {
  New-Item -ItemType Directory -Path $Target -Force | Out-Null
  Copy-Item -Path (Join-Path $RepoRoot ".github") -Destination (Join-Path $Target ".github") -Recurse -Force
  Copy-Item -Path (Join-Path $RepoRoot "docs") -Destination (Join-Path $Target "docs") -Recurse -Force
  # The hook audit log is machine-local state, not repository truth, and no
  # fixture reads it. Prune it before any fixture runs so a fixture copy never
  # carries local audit data.
  Remove-Item -Path (Join-Path $Target ".github/hooks/logs") -Recurse -Force -ErrorAction SilentlyContinue
}

function Get-FixtureNonMutatingTier([string]$Target) {
  # Derive the tier exactly as the validator body does: allow-listed agent files
  # whose declared capabilities are a subset of read, search, and todo. Both the
  # tier mutation and the tolerated-state fixture derive it here, so the two
  # cannot drift apart. Sort-Object Name keeps the member order identical to the
  # Bash twin's sorted glob, so a position-based mutation targets the same member
  # on both platforms.
  $policyPath = Join-Path $Target ".github/roles/orchestration-policy.json"
  $allow = @((Get-Content -Path $policyPath -Raw | ConvertFrom-Json).specialistAllowList)
  $tier = @()
  foreach ($agentFile in @(Get-ChildItem -Path (Join-Path $Target ".github/agents") -Filter "*.agent.md" -File | Sort-Object Name)) {
    $agentName = $agentFile.Name.Substring(0, $agentFile.Name.Length - ".agent.md".Length)
    if ($allow -cnotcontains $agentName) { continue }
    $agentText = Get-Content -Path $agentFile.FullName -Raw
    $toolsMatch = [regex]::Match($agentText, "(?m)^tools:\s*\[([^\]]*)\]")
    if (-not $toolsMatch.Success) { continue }
    $agentTools = @($toolsMatch.Groups[1].Value -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $mutatingTools = @($agentTools | Where-Object { @("read", "search", "todo") -cnotcontains $_ })
    if ($mutatingTools.Count -ne 0) { continue }
    $tier += [pscustomobject]@{
      Name = $agentName
      Path = $agentFile.FullName
      Text = $agentText
      Tools = $agentTools
    }
  }
  return $tier
}

function Set-FixtureMutation([string]$Mutation, [string]$Target) {
  switch ($Mutation) {
    "enabled-by-default" {
      $path = Join-Path $Target ".github/starter-modules.json"
      $manifest = Get-Content -Path $path -Raw | ConvertFrom-Json
      foreach ($module in $manifest.modules) {
        if ($module.id -eq "overlay-supervisor-orchestration") { $module.defaultEnabled = $true }
      }
      $manifest | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "second-delegation-owner" {
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $access.agentCapabilityMatrix.qa.tools | Add-Member -NotePropertyName "delegate-agent" -NotePropertyValue $true -Force
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "worker-role-delegation" {
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $access.roles.review.tools += "delegate-agent"
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "frontmatter-divergence" {
      $path = Join-Path $Target ".github/agents/delegation-supervisor.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]", "tools: [read, search, todo, edit]"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "write-delegation-without-write-set" {
      $path = Join-Path $Target ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json"
      $example = Get-Content -Path $path -Raw | ConvertFrom-Json
      foreach ($delegation in @($example.delegations)) {
        if ($delegation.capability -eq "write") {
          $delegation.PSObject.Properties.Remove("writeSet")
        }
      }
      $example | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "unbounded-write-set" {
      $path = Join-Path $Target ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json"
      $example = Get-Content -Path $path -Raw | ConvertFrom-Json
      foreach ($delegation in @($example.delegations)) {
        if ($delegation.capability -eq "write") {
          $delegation.writeSet = @("TBD")
          break
        }
      }
      $example | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "enforcement-overclaim" {
      $path = Join-Path $Target ".github/agent-catalog.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "high-risk approval gate that is a prompt-level contract, not enforcement", "high-risk approval enforcement"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "worker-frontmatter-delegation" {
      $path = Join-Path $Target ".github/agents/qa.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]", "tools: [read, search, execute, todo, delegate-agent]"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "unregistered-delegation-holder" {
      $roguePath = Join-Path $Target ".github/agents/rogue-worker.agent.md"
      $rogueContent = @(
        "---"
        'description: "Fixture agent that declares delegation without a capability-matrix entry."'
        "tools: [read, search, todo, delegate-agent]"
        "user-invocable: false"
        "---"
        "Fixture agent used to prove the frontmatter scan catches an agent file"
        "that escapes the capability matrix entirely."
      ) -join "`n"
      Set-Content -Path $roguePath -Value $rogueContent -Encoding utf8
    }
    "allow-list-delegation-holder" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $mutatedAllowList = @($policy.specialistAllowList) + @("delegation-supervisor")
      $policy.specialistAllowList = @($mutatedAllowList | Sort-Object -Unique)
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "frontmatter-matrix-mismatch" {
      $path = Join-Path $Target ".github/agents/qa.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]", "tools: [read, search, todo]"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "role-hint-mismatch" {
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $access.agentRoleHints.qa = "review"
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "matrix-entry-without-agent-file" {
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $entry = [pscustomobject]@{
        role = "review"
        scope = "Fixture matrix entry with no matching agent file."
        tools = [pscustomobject]@{ read = $true; search = $true; todo = $true }
      }
      $access.agentCapabilityMatrix | Add-Member -NotePropertyName "ghost-worker" -NotePropertyValue $entry -Force
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "registered-agent-without-tools-list" {
      $path = Join-Path $Target ".github/agents/qa.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]`r?`n", ""
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "matrix-tool-absent-from-tool-definitions" {
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $access.agentCapabilityMatrix.qa.tools | Add-Member -NotePropertyName "browse-web" -NotePropertyValue $true -Force
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "enforcement-wording-in-agent-file" {
      $path = Join-Path $Target ".github/agents/delegation-supervisor.agent.md"
      Add-Content -Path $path -Value "`nThe supervisor enforces the high-risk approval boundary." -Encoding utf8
    }
    "allow-listed-agent-without-matrix-entry" {
      # The tolerated state the runbook documents and the tier fixture depends on:
      # the frontmatter scan is authoritative, so an allow-listed agent file with
      # no agentCapabilityMatrix entry is accepted rather than rejected. Pinned by
      # a positive fixture so a later hardening that rejects it goes red instead
      # of silently breaking a documented contract.
      $tier = @(Get-FixtureNonMutatingTier -Target $Target)
      if ($tier.Count -eq 0) {
        throw "Positive fixture could not be applied: the specialist allow-list has no non-mutating tier to remove a matrix entry from"
      }
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $matrixProperty = $access.PSObject.Properties["agentCapabilityMatrix"]
      if (($null -eq $matrixProperty) -or ($null -eq $matrixProperty.Value.PSObject.Properties[$tier[0].Name])) {
        throw "Positive fixture could not be applied: $($tier[0].Name) has no agentCapabilityMatrix entry to remove"
      }
      $matrixProperty.Value.PSObject.Properties.Remove($tier[0].Name)
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "empty-non-mutating-tier" {
      # Derive the tier the same way the validator does, then make every member
      # able to mutate state. Where a matrix entry exists, the frontmatter and the
      # entry must move together or the agreement check fires as well; errors
      # accumulate, so the tier diagnostic is still the one asserted on.
      # An allow-listed agent file with no agentCapabilityMatrix entry is a state
      # the validator accepts and the runbook documents, so the fixture must also
      # survive it: the last member's entry is removed before the loop starts, and
      # that removal is what the self-check below pins.
      $nonMutating = @(Get-FixtureNonMutatingTier -Target $Target)

      $accessPath = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $accessPath -Raw | ConvertFrom-Json
      $matrixEntryProperty = $access.PSObject.Properties["agentCapabilityMatrix"]
      $matrix = $null
      if ($null -ne $matrixEntryProperty) { $matrix = $matrixEntryProperty.Value }

      # Pre-removing the last member rather than the first keeps the missing-entry
      # state on a non-zero index for any tier larger than one, so the loop cannot
      # reach it by accident, and it is the sole member when the tier holds exactly
      # one agent. The condition is that the tier is non-empty, not that it holds
      # more than one member: a single-member tier is a legal state, so gating the
      # removal on the tier size would let a governance edit drop it silently and
      # return this fixture to the unexercised state it exists to prevent.
      if (($nonMutating.Count -gt 0) -and ($null -ne $matrix)) {
        $matrix.PSObject.Properties.Remove($nonMutating[-1].Name)
      }

      $entriesSeenMissing = 0
      foreach ($member in $nonMutating) {
        $matrixEntry = $null
        if ($null -ne $matrix) { $matrixEntry = $matrix.PSObject.Properties[$member.Name] }
        if ($null -eq $matrixEntry) {
          $entriesSeenMissing++
        } elseif ($null -ne $matrixEntry.Value.PSObject.Properties["tools"]) {
          $matrixEntry.Value.tools | Add-Member -NotePropertyName "edit" -NotePropertyValue $true -Force
        }
        $toolsMatch = [regex]::Match($member.Text, "(?m)^tools:\s*\[([^\]]*)\]")
        $replacement = "tools: [" + (@($member.Tools + "edit") -join ", ") + "]"
        $mutatedText = $member.Text.Remove($toolsMatch.Index, $toolsMatch.Length).Insert($toolsMatch.Index, $replacement)
        Set-Content -Path $member.Path -Value $mutatedText -Encoding utf8
      }

      # The fixture is only meaningful if the mutation actually reached the
      # missing-entry state. Without this, dropping the pre-removal above would
      # silently return the fixture to a state where the missing-entry branch is
      # never exercised and the fixture still passes, which is the defect this
      # fixture guards. The check is unconditional: it holds for every non-empty
      # tier size, a single-member tier included.
      if ($entriesSeenMissing -eq 0) {
        throw "Negative fixture could not be applied: the mutation loop never observed an allow-listed tier member without an agentCapabilityMatrix entry, so the missing-entry path is unexercised"
      }

      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $accessPath -Encoding utf8
    }
    "worker-agent-tool-delegation" {
      $path = Join-Path $Target ".github/agents/qa.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]", "tools: [read, search, execute, todo, agent]"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "worker-agents-key-delegation" {
      $path = Join-Path $Target ".github/agents/qa.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^(tools:\s*\[[^\]]*\]\r?\n)", "`$1agents: ['senior-software-engineer']`n"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "supervisor-agents-key-off-allow-list" {
      $path = Join-Path $Target ".github/agents/delegation-supervisor.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^(tools:\s*\[[^\]]*\]\r?\n)", "`$1agents: ['fixture-off-allow-list-agent']`n"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "worker-block-style-tools-delegation" {
      $path = Join-Path $Target ".github/agents/qa.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]", "tools:`n  - read`n  - search`n  - execute`n  - todo`n  - agent"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "worker-block-style-agents-key-delegation" {
      $path = Join-Path $Target ".github/agents/qa.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^(tools:\s*\[[^\]]*\]\r?\n)", "`$1agents:`n  - senior-software-engineer`n"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "supervisor-agents-without-host-tool" {
      $path = Join-Path $Target ".github/agents/delegation-supervisor.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]", "tools: [read, search, todo, delegate-agent]"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "supervisor-host-tool-without-agents" {
      $path = Join-Path $Target ".github/agents/delegation-supervisor.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^agents:\s*\[[^\]]*\]\r?\n", ""
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "adapter-mutating-capability" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $hostAdaptersProperty = $policy.delegationDepth.PSObject.Properties["hostAdapters"]
      if (($null -eq $hostAdaptersProperty) -or ($null -eq $hostAdaptersProperty.Value)) {
        throw "Negative fixture could not be applied: hostAdapters is empty"
      }
      $firstHost = @($hostAdaptersProperty.Value.PSObject.Properties)[0]
      $mutatedTools = New-Object System.Collections.Generic.List[object]
      foreach ($tool in @($firstHost.Value.delegationTools)) { $mutatedTools.Add($tool) }
      $mutatedTools.Add("edit")
      $firstHost.Value.delegationTools = $mutatedTools.ToArray()
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "supervisor-frontmatter-extra-tool" {
      $path = Join-Path $Target ".github/agents/delegation-supervisor.agent.md"
      $mutated = (Get-Content -Path $path -Raw) -replace "(?m)^tools:\s*\[[^\]]*\]", "tools: [read, search, todo, delegate-agent, agent, spawn-agent]"
      Set-Content -Path $path -Value $mutated -Encoding utf8
    }
    "non-allow-listed-agent-without-matrix-entry" {
      $roguePath = Join-Path $Target ".github/agents/rogue-advisor.agent.md"
      $rogueContent = @(
        "---"
        'description: "Fixture agent off the allow-list with no capability-matrix entry."'
        "tools: [read, search, todo]"
        "user-invocable: false"
        "---"
        "Fixture agent used to prove the registration rule rejects an agent file"
        "that is not on the specialist allow-list and has no matrix entry."
      ) -join "`n"
      Set-Content -Path $roguePath -Value $rogueContent -Encoding utf8
    }
    "non-allow-listed-agent-without-role-hint" {
      $roguePath = Join-Path $Target ".github/agents/rogue-advisor.agent.md"
      $rogueContent = @(
        "---"
        'description: "Fixture agent off the allow-list with no role hint."'
        "tools: [read, search, todo]"
        "user-invocable: false"
        "---"
        "Fixture agent used to prove the registration rule rejects an agent file"
        "that is not on the specialist allow-list and has no role hint."
      ) -join "`n"
      Set-Content -Path $roguePath -Value $rogueContent -Encoding utf8
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $entry = [pscustomobject]@{
        role = "review"
        scope = "Fixture matrix entry for an agent file with no role hint."
        tools = [pscustomobject]@{ read = $true; search = $true; todo = $true }
      }
      $access.agentCapabilityMatrix | Add-Member -NotePropertyName "rogue-advisor" -NotePropertyValue $entry -Force
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "unsupported-host-empty-adapter-list" {
      # The accepted representation for a host with no verified delegation
      # primitive: an adapter entry with an empty delegationTools list. Pinned by
      # a positive fixture so one twin cannot start rejecting it without a check
      # going red on both platforms.
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $entry = [pscustomobject]@{
        delegationTools = @()
        note = "Fixture host with no verified delegation primitive, recorded as an empty tool list."
      }
      $policy.delegationDepth.PSObject.Properties["hostAdapters"].Value | Add-Member -NotePropertyName "cursor" -NotePropertyValue $entry -Force
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "adapter-enabled-in-capability-matrix" {
      $path = Join-Path $Target ".github/roles/tool-access.json"
      $access = Get-Content -Path $path -Raw | ConvertFrom-Json
      $matrixEntry = $access.agentCapabilityMatrix.PSObject.Properties["orchestration-coordinator"].Value
      $matrixEntry.tools | Add-Member -NotePropertyName "agent" -NotePropertyValue $true -Force
      $access | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "adapter-case-variant-tool-name" {
      # The mutating-name guard matches case-sensitively, so a case variant of a
      # mutating name is a distinct host tool name and is accepted. Pinned by a
      # positive fixture so one twin cannot drift to a case-insensitive match
      # that would reject this state without a check going red on both platforms.
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $hostAdaptersProperty = $policy.delegationDepth.PSObject.Properties["hostAdapters"]
      if (($null -eq $hostAdaptersProperty) -or ($null -eq $hostAdaptersProperty.Value)) {
        throw "Positive fixture could not be applied: hostAdapters is empty"
      }
      $firstHost = @($hostAdaptersProperty.Value.PSObject.Properties)[0]
      $mutatedTools = New-Object System.Collections.Generic.List[object]
      foreach ($tool in @($firstHost.Value.delegationTools)) { $mutatedTools.Add($tool) }
      $mutatedTools.Add("EDIT")
      $firstHost.Value.delegationTools = $mutatedTools.ToArray()
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "removed-task-class" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $classes = @($policy.taskClasses)
      if (@($classes | Where-Object { $_.id -eq "QUESTION" }).Count -eq 0) {
        throw "Negative fixture could not be applied: taskClasses has no QUESTION entry to remove"
      }
      $policy.taskClasses = @($classes | Where-Object { $_.id -ne "QUESTION" })
      if ($null -ne $policy.playbooks) {
        $policy.playbooks.PSObject.Properties.Remove("QUESTION")
      }
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "empty-playbook" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      if ($null -eq $policy.playbooks -or $null -eq $policy.playbooks.PSObject.Properties["DOCUMENTATION"]) {
        throw "Negative fixture could not be applied: playbooks has no DOCUMENTATION playbook to empty"
      }
      $policy.playbooks.DOCUMENTATION = @()
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "playbook-stage-off-allow-list" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $stages = @($policy.playbooks.QUESTION)
      if ($stages.Count -eq 0) {
        throw "Negative fixture could not be applied: playbooks has no QUESTION stages to mutate"
      }
      $stages[0].delegatesTo = @("rogue-agent")
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "playbook-stage-both-delegation-and-approval" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $stages = @($policy.playbooks.QUESTION)
      if ($stages.Count -lt 2) {
        throw "Negative fixture could not be applied: playbooks has fewer than two QUESTION stages to mutate"
      }
      $stages[1] | Add-Member -NotePropertyName "requiresHumanApproval" -NotePropertyValue $true -Force
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "playbook-unknown-class-id" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $ghostStage = [pscustomobject]@{
        id = "ghost-stage"
        name = "Ghost stage"
        delegatesTo = @("analyst")
        skipRequiresReason = $true
      }
      $policy.playbooks | Add-Member -NotePropertyName "GHOST_CLASS" -NotePropertyValue @($ghostStage) -Force
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "mutated-evidence-vocabulary" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $policy.evidenceRequirements.resultVocabulary = @("VERIFIED", "NOT_VERIFIED", "MAYBE")
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "unknown-evidence-surface" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $networkSurface = [pscustomobject]@{ evidence = @("ping-the-service") }
      $policy.evidenceRequirements.surfaces | Add-Member -NotePropertyName "network" -NotePropertyValue $networkSurface -Force
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "edited-completion-rule" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $policy.evidenceRequirements.completionRule = "agent-declared-after-self-report"
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "complexity-default-not-complex" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $policy.complexityRouting.defaultWhenUncertain = "simple"
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "complexity-empty-simple-workflow" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $policy.complexityRouting.simpleWorkflow = ""
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "complexity-empty-complex-workflow" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $policy.complexityRouting.complexWorkflow = ""
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "complexity-empty-complexIfAny" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $policy.complexityRouting.complexIfAny = @()
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "complexity-empty-notBasedOn" {
      $path = Join-Path $Target ".github/roles/orchestration-policy.json"
      $policy = Get-Content -Path $path -Raw | ConvertFrom-Json
      $policy.complexityRouting.notBasedOn = @()
      $policy | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    "malformed-delegation-result" {
      $path = Join-Path $Target ".github/examples/supervisor-orchestration/simple-bugfix-delegation-result.json"
      $result = Get-Content -Path $path -Raw | ConvertFrom-Json
      if ($null -eq $result.PSObject.Properties["verificationPerformed"]) {
        throw "Negative fixture could not be applied: delegation-result example has no verificationPerformed to remove"
      }
      $result.PSObject.Properties.Remove("verificationPerformed")
      $result | ConvertTo-Json -Depth 20 | Set-Content -Path $path -Encoding utf8
    }
    default {
      throw "Unknown fixture mutation: $Mutation"
    }
  }
}

function Invoke-FixtureValidator([string]$Target) {
  $previous = $env:SUPERVISOR_SKIP_FIXTURES
  $env:SUPERVISOR_SKIP_FIXTURES = "1"
  $logPath = [System.IO.Path]::GetTempFileName()
  try {
    & pwsh -NoProfile -File $ValidatorPath -RepoRoot $Target *> $logPath
    $status = $LASTEXITCODE
    $output = Get-Content -Path $logPath -Raw
    return [pscustomobject]@{ Status = $status; Output = $output }
  } finally {
    $env:SUPERVISOR_SKIP_FIXTURES = $previous
    Remove-Item -Path $logPath -Force -ErrorAction SilentlyContinue
  }
}

function Test-NegativeFixture([string]$Mutation, [string]$Description, [string]$Expected) {
  $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("sov-fixture-" + [guid]::NewGuid().ToString("N"))
  try {
    Copy-FixtureRoot -Target $fixtureRoot
    Set-FixtureMutation -Mutation $Mutation -Target $fixtureRoot

    $result = Invoke-FixtureValidator -Target $fixtureRoot
    if ($result.Status -eq 0) {
      Add-CheckError("Negative fixture not detected: $Description")
    } elseif ($result.Output -notlike "*$Expected*") {
      Add-CheckError("Negative fixture failed for the wrong reason: $Description")
    }
  } catch {
    # A setup or mutation failure must be reported as a fixture error rather
    # than terminating the run, which would skip every remaining fixture.
    Add-CheckError("Negative fixture could not be applied: $Description ($($_.Exception.Message))")
  } finally {
    Remove-Item -Path $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Test-PositiveFixture([string]$Mutation, [string]$Description) {
  $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("sov-fixture-" + [guid]::NewGuid().ToString("N"))
  try {
    Copy-FixtureRoot -Target $fixtureRoot
    Set-FixtureMutation -Mutation $Mutation -Target $fixtureRoot

    $result = Invoke-FixtureValidator -Target $fixtureRoot
    if ($result.Status -ne 0) {
      Add-CheckError("Positive fixture rejected an accepted state: $Description")
      Write-Host $result.Output
    }
  } catch {
    # Same contract as the negative fixtures: a setup or mutation failure is
    # reported rather than terminating the run, and the copy is removed either
    # way.
    Add-CheckError("Positive fixture could not be applied: $Description ($($_.Exception.Message))")
  } finally {
    Remove-Item -Path $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

