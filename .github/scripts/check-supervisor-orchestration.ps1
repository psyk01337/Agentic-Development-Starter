param(
  [string]$RepoRoot = ""
)

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
} else {
  $RepoRoot = Resolve-Path $RepoRoot
}

$errors = New-Object System.Collections.Generic.List[string]

function Add-CheckError([string]$Message) {
  $script:errors.Add($Message)
}

function Assert-FileExists([string]$RelativePath) {
  $fullPath = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $fullPath)) {
    Add-CheckError("Missing required file: $RelativePath")
  }
}

function Assert-FileContains([string]$RelativePath, [string]$Pattern, [string]$Description) {
  $fullPath = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $fullPath)) {
    Add-CheckError("Cannot verify $Description because file is missing: $RelativePath")
    return
  }

  $content = Get-Content -Path $fullPath -Raw
  if ($content -cnotmatch $Pattern) {
    Add-CheckError("Missing expected content for $Description in $RelativePath")
  }
}

function Get-SchemaInstanceProblems {
  param(
    $Instance,
    $Schema,
    [string]$Path = '$'
  )

  $problems = New-Object System.Collections.Generic.List[string]

  $allOfKeyword = $Schema.PSObject.Properties['allOf']
  if ($null -ne $allOfKeyword) {
    foreach ($subschema in @($allOfKeyword.Value)) {
      foreach ($problem in @(Get-SchemaInstanceProblems -Instance $Instance -Schema $subschema -Path $Path)) {
        $problems.Add($problem)
      }
    }
  }

  $ifKeyword = $Schema.PSObject.Properties['if']
  if ($null -ne $ifKeyword) {
    $conditionMet = @(Get-SchemaInstanceProblems -Instance $Instance -Schema $ifKeyword.Value -Path $Path).Count -eq 0
    $thenKeyword = $Schema.PSObject.Properties['then']
    if ($conditionMet -and $null -ne $thenKeyword) {
      foreach ($problem in @(Get-SchemaInstanceProblems -Instance $Instance -Schema $thenKeyword.Value -Path $Path)) {
        $problems.Add($problem)
      }
    }
  }

  $typeKeyword = $Schema.PSObject.Properties['type']
  if ($null -ne $typeKeyword) {
    $expectedType = $typeKeyword.Value
    $matched = switch ($expectedType) {
      'object' { $Instance -is [System.Management.Automation.PSCustomObject] }
      'array' { $Instance -is [System.Array] }
      'string' { $Instance -is [string] }
      'boolean' { $Instance -is [bool] }
      default { $true }
    }
    if (-not $matched) {
      $problems.Add("${Path}: expected $expectedType")
      return $problems.ToArray()
    }
  }

  if ($Instance -is [System.Management.Automation.PSCustomObject]) {
    $propertyNames = @($Instance.PSObject.Properties.Name)
    $propertiesKeyword = $Schema.PSObject.Properties['properties']
    $properties = $null
    if ($null -ne $propertiesKeyword) { $properties = $propertiesKeyword.Value }
    $declaredNames = @()
    if ($null -ne $properties) { $declaredNames = @($properties.PSObject.Properties.Name) }

    $requiredKeyword = $Schema.PSObject.Properties['required']
    if ($null -ne $requiredKeyword) {
      foreach ($name in @($requiredKeyword.Value)) {
        if ($propertyNames -notcontains $name) {
          $problems.Add("${Path}: missing required property '$name'")
        }
      }
    }

    $additionalKeyword = $Schema.PSObject.Properties['additionalProperties']
    if ($null -ne $additionalKeyword -and $additionalKeyword.Value -eq $false) {
      foreach ($name in $propertyNames) {
        if ($declaredNames -notcontains $name) {
          $problems.Add("${Path}: unexpected property '$name'")
        }
      }
    }

    foreach ($name in $propertyNames) {
      if ($declaredNames -contains $name) {
        $childPath = "${Path}.${name}"
        $childSchema = $properties.PSObject.Properties[$name].Value
        foreach ($problem in @(Get-SchemaInstanceProblems -Instance $Instance.$name -Schema $childSchema -Path $childPath)) {
          $problems.Add($problem)
        }
      }
    }
  } elseif ($Instance -is [System.Array]) {
    $minItemsKeyword = $Schema.PSObject.Properties['minItems']
    if ($null -ne $minItemsKeyword -and @($Instance).Count -lt $minItemsKeyword.Value) {
      $problems.Add("${Path}: fewer than minItems $($minItemsKeyword.Value)")
    }
    $itemsKeyword = $Schema.PSObject.Properties['items']
    if ($null -ne $itemsKeyword -and $null -ne $itemsKeyword.Value) {
      for ($index = 0; $index -lt @($Instance).Count; $index++) {
        foreach ($problem in @(Get-SchemaInstanceProblems -Instance $Instance[$index] -Schema $itemsKeyword.Value -Path "${Path}[$index]")) {
          $problems.Add($problem)
        }
      }
    }
  } elseif ($Instance -is [string]) {
    $minLengthKeyword = $Schema.PSObject.Properties['minLength']
    if ($null -ne $minLengthKeyword -and $Instance.Length -lt $minLengthKeyword.Value) {
      $problems.Add("${Path}: shorter than minLength $($minLengthKeyword.Value)")
    }
  }

  $constKeyword = $Schema.PSObject.Properties['const']
  if ($null -ne $constKeyword -and $Instance -ne $constKeyword.Value) {
    $problems.Add("${Path}: expected const '$($constKeyword.Value)'")
  }
  $enumKeyword = $Schema.PSObject.Properties['enum']
  if ($null -ne $enumKeyword -and @($enumKeyword.Value) -notcontains $Instance) {
    $problems.Add("${Path}: value '$Instance' is not in the schema enum")
  }

  return $problems.ToArray()
}

function Get-SchemaExampleProblems {
  param(
    $Schema,
    $Example,
    $Policy
  )

  $problems = New-Object System.Collections.Generic.List[string]
  foreach ($problem in @(Get-SchemaInstanceProblems -Instance $Example -Schema $Schema)) {
    $problems.Add($problem)
  }

  $schemaAllowList = @()
  $enumKeyword = $Schema.properties.delegations.items.properties.agent.PSObject.Properties['enum']
  if ($null -ne $enumKeyword) { $schemaAllowList = @($enumKeyword.Value) }
  $policyAllowList = @($Policy.specialistAllowList)
  $drift = @(@($schemaAllowList | Where-Object { $policyAllowList -notcontains $_ }) + @($policyAllowList | Where-Object { $schemaAllowList -notcontains $_ }))
  if ($drift.Count -gt 0) {
    $problems.Add("delegation-plan.schema.json agent enum has drifted from the canonical policy allow-list")
  }

  return $problems.ToArray()
}

$requiredFiles = @(
  ".github/agents/delegation-supervisor.agent.md",
  ".github/skills/supervisor-orchestration/SKILL.md",
  ".github/roles/orchestration-policy.json",
  ".github/schema/delegation-plan.schema.json",
  ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json",
  ".github/scripts/check-supervisor-orchestration.ps1",
  ".github/scripts/check-supervisor-orchestration.sh",
  "docs/runbooks/supervisor-orchestration.md",
  "docs/adr/0003-supervisor-orchestration-overlay.md"
)

foreach ($relativePath in $requiredFiles) {
  Assert-FileExists -RelativePath $relativePath
}

$expectedRoleTools = @("read", "search", "todo", "delegate-agent")
$toolDefinitionNames = @()
$matrixEntries = @{}
$allowList = @()

$manifestPath = Join-Path $RepoRoot ".github/starter-modules.json"
if (-not (Test-Path $manifestPath)) {
  Add-CheckError("Missing required file: .github/starter-modules.json")
} else {
  $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
  $overlay = $manifest.modules | Where-Object { $_.id -eq "overlay-supervisor-orchestration" }
  if (-not $overlay) {
    Add-CheckError("starter-modules.json is missing overlay-supervisor-orchestration")
  } else {
    if ($overlay.kind -ne "overlay") {
      Add-CheckError("overlay-supervisor-orchestration must have kind 'overlay'")
    }
    if ($overlay.defaultEnabled -ne $false) {
      Add-CheckError("overlay-supervisor-orchestration must be default-disabled")
    }
    foreach ($relativePath in $overlay.files) {
      if (-not (Test-Path (Join-Path $RepoRoot $relativePath))) {
        Add-CheckError("Manifest-listed overlay file does not exist: $relativePath")
      }
    }
  }
}

$accessPath = Join-Path $RepoRoot ".github/roles/tool-access.json"
if (-not (Test-Path $accessPath)) {
  Add-CheckError("Missing required file: .github/roles/tool-access.json")
} else {
  $access = Get-Content -Path $accessPath -Raw | ConvertFrom-Json

  $toolDefinitionNames = @($access.toolDefinitions.PSObject.Properties.Name)
  foreach ($entry in $access.agentCapabilityMatrix.PSObject.Properties) {
    $matrixEntries[$entry.Name] = $entry.Value
  }

  if (-not ($access.toolDefinitions.PSObject.Properties.Name -contains "delegate-agent")) {
    Add-CheckError("tool-access.json toolDefinitions is missing delegate-agent")
  }

  $roleNames = $access.roles.PSObject.Properties.Name
  if ($roleNames -notcontains "orchestration") {
    Add-CheckError("tool-access.json roles is missing the orchestration role")
  } else {
    $roleTools = @($access.roles.orchestration.tools)
    $missingRoleTool = $expectedRoleTools | Where-Object { $roleTools -notcontains $_ }
    $extraRoleTool = $roleTools | Where-Object { $expectedRoleTools -notcontains $_ }
    if ($missingRoleTool -or $extraRoleTool) {
      Add-CheckError("orchestration role tools must be exactly $($expectedRoleTools -join ', ')")
    }
    foreach ($forbidden in @("edit", "execute")) {
      if ($roleTools -contains $forbidden) {
        Add-CheckError("orchestration role must not include $forbidden")
      }
    }
  }

  $matrixNames = $access.agentCapabilityMatrix.PSObject.Properties.Name
  if ($matrixNames -notcontains "delegation-supervisor") {
    Add-CheckError("agentCapabilityMatrix is missing delegation-supervisor")
  } else {
    $supervisor = $access.agentCapabilityMatrix.'delegation-supervisor'
    if ($supervisor.role -ne "orchestration") {
      Add-CheckError("delegation-supervisor must use the orchestration role")
    }
    if ($supervisor.tools.'delegate-agent' -ne $true) {
      Add-CheckError("delegation-supervisor must hold delegate-agent")
    }
    if ($supervisor.tools.edit -ne $false) {
      Add-CheckError("delegation-supervisor must not hold edit")
    }
    if ($supervisor.tools.execute -ne $false) {
      Add-CheckError("delegation-supervisor must not hold execute")
    }
    foreach ($required in @("read", "search", "todo")) {
      if ($supervisor.tools.$required -ne $true) {
        Add-CheckError("delegation-supervisor must declare $required")
      }
    }
  }

  if ($access.agentRoleHints.'delegation-supervisor' -ne "orchestration") {
    Add-CheckError("agentRoleHints must map delegation-supervisor to orchestration")
  }
  foreach ($hint in $access.agentRoleHints.PSObject.Properties) {
    if ($matrixEntries.ContainsKey($hint.Name) -and $matrixEntries[$hint.Name].role -ne $hint.Value) {
      Add-CheckError("agentRoleHints entry disagrees with agentCapabilityMatrix role for $($hint.Name): hint $($hint.Value), matrix $($matrixEntries[$hint.Name].role)")
    }
  }

  foreach ($role in $access.roles.PSObject.Properties) {
    if ($role.Name -ne "orchestration" -and (@($role.Value.tools) -contains "delegate-agent")) {
      Add-CheckError("only the orchestration role may hold delegate-agent; found in $($role.Name)")
    }
  }
  foreach ($entry in $access.agentCapabilityMatrix.PSObject.Properties) {
    if ($entry.Name -ne "delegation-supervisor" -and $entry.Value.tools.'delegate-agent' -eq $true) {
      Add-CheckError("only delegation-supervisor may hold delegate-agent; found in $($entry.Name)")
    }
  }
}

$policyPath = Join-Path $RepoRoot ".github/roles/orchestration-policy.json"
if (-not (Test-Path $policyPath)) {
  Add-CheckError("Missing required file: .github/roles/orchestration-policy.json")
} else {
  $policy = Get-Content -Path $policyPath -Raw | ConvertFrom-Json

  if ($policy.delegationDepth.maxLevels -ne 1) {
    Add-CheckError("orchestration-policy.json must set delegationDepth.maxLevels to 1")
  }
  if ($policy.delegationDepth.nestedDelegationEnabled -ne $false) {
    Add-CheckError("orchestration-policy.json must disable nested delegation")
  }
  if ($policy.delegationDepth.onlySupervisorMayDelegate -ne $true) {
    Add-CheckError("orchestration-policy.json must restrict delegation to the supervisor")
  }
  if ($policy.delegationDepth.workersMayDelegate -ne $false) {
    Add-CheckError("orchestration-policy.json must deny worker delegation (workersMayDelegate: false)")
  }
  if ($policy.enforcement.runtimeEnforced -ne $false) {
    Add-CheckError("orchestration-policy.json must not claim runtime enforcement (enforcement.runtimeEnforced: false)")
  }
  if ($policy.writeSet.requiredBeforeWriteDelegation -ne $true) {
    Add-CheckError("orchestration-policy.json must require a declared write set before write delegation")
  }
  if ($policy.fallbackWhenDelegationUnavailable.silentDegradationAllowed -ne $false) {
    Add-CheckError("orchestration-policy.json must forbid silent degradation (silentDegradationAllowed: false)")
  }
  if ($policy.deferredProposal.status -ne "deferred-not-rejected") {
    Add-CheckError("orchestration-policy.json must keep the deferred proposal as 'deferred-not-rejected'")
  }
  if ($policy.approvalOverlayComposition.hardDependency -ne $false) {
    Add-CheckError("orchestration-policy.json must not declare a hard dependency on the approval overlay")
  }

  $allowList = @($policy.specialistAllowList)
  if ($allowList.Count -eq 0) {
    Add-CheckError("orchestration-policy.json must define a specialist allow-list")
  }
  foreach ($requiredAgent in @(
      "analyst",
      "tech-planner",
      "architecture-reviewer",
      "senior-software-engineer",
      "code-reviewer",
      "security-reviewer",
      "qa",
      "tdd-vitest",
      "documentation-maintainer"
    )) {
    if ($allowList -notcontains $requiredAgent) {
      Add-CheckError("specialist allow-list is missing $requiredAgent")
    }
  }

  $categories = @($policy.approvalRequiredCategories | ForEach-Object { $_.id })
  foreach ($requiredCategory in @(
      "architecture-change",
      "core-governance-change",
      "dependency-change",
      "destructive-data-change",
      "identity-security-change",
      "production-or-deployment-change",
      "destructive-operation",
      "scope-expansion"
    )) {
    if ($categories -notcontains $requiredCategory) {
      Add-CheckError("approval-required categories are missing $requiredCategory")
    }
  }

  $schemaPath = Join-Path $RepoRoot ".github/schema/delegation-plan.schema.json"
  $examplePath = Join-Path $RepoRoot ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json"
  if (-not (Test-Path $schemaPath)) {
    Add-CheckError("Missing required file: .github/schema/delegation-plan.schema.json")
  } elseif (-not (Test-Path $examplePath)) {
    Add-CheckError("Missing required file: .github/examples/supervisor-orchestration/complex-feature-delegation-plan.json")
  } else {
    $schema = Get-Content -Path $schemaPath -Raw | ConvertFrom-Json
    $example = Get-Content -Path $examplePath -Raw | ConvertFrom-Json
    foreach ($problem in @(Get-SchemaExampleProblems -Schema $schema -Example $example -Policy $policy)) {
      Add-CheckError($problem)
    }

    # A declared write set that is literally one of the policy's unbounded
    # indicators means the work must be serialized, not run in parallel.
    $unboundedIndicators = @($policy.writeSet.unboundedIndicators)
    $delegationIndex = 0
    foreach ($delegation in @($example.delegations)) {
      foreach ($entry in @($delegation.writeSet)) {
        if ($entry -and ($unboundedIndicators -contains $entry)) {
          Add-CheckError("delegations[$delegationIndex].writeSet declares an unbounded indicator '$entry'; serialize the write delegation instead of running it in parallel")
        }
      }
      $delegationIndex++
    }
  }
}

# Sole-holder invariant, checked over every agent file rather than only the
# capability matrix. A new agent file can appear without a matrix entry, so the
# frontmatter scan is the authoritative path and the matrix must then agree with
# it, in both directions.
$agentsDirectory = Join-Path $RepoRoot ".github/agents"
$agentFiles = @()
if (Test-Path $agentsDirectory) {
  $agentFiles = @(Get-ChildItem -Path $agentsDirectory -Filter "*.agent.md" -File | Sort-Object Name)
}
if ($agentFiles.Count -eq 0) {
  Add-CheckError("No agent files found under .github/agents")
}

$frontmatterTools = @{}
$agentsWithoutToolsList = @()
foreach ($agentFile in $agentFiles) {
  $agentName = $agentFile.Name.Substring(0, $agentFile.Name.Length - ".agent.md".Length)
  $agentText = Get-Content -Path $agentFile.FullName -Raw
  $match = [regex]::Match($agentText, "(?m)^tools:\s*\[([^\]]*)\]")
  if (-not $match.Success) {
    # tools: is optional in .agent.md frontmatter, so an unregistered agent file
    # is not required to declare one. Only a registered capability boundary
    # makes the list load-bearing.
    $agentsWithoutToolsList += $agentName
    continue
  }
  $frontmatterTools[$agentName] = @(
    $match.Groups[1].Value -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  )
}

if ($frontmatterTools.ContainsKey('delegation-supervisor')) {
  $supervisorTools = @($frontmatterTools['delegation-supervisor'])
  $missingTool = $expectedRoleTools | Where-Object { $supervisorTools -notcontains $_ }
  $extraTool = $supervisorTools | Where-Object { $expectedRoleTools -notcontains $_ }
  if ($missingTool -or $extraTool) {
    Add-CheckError("delegation-supervisor frontmatter tools must be exactly $((@($expectedRoleTools | Sort-Object)) -join ', '); found $((@($supervisorTools | Sort-Object)) -join ', ')")
  }
}

foreach ($entry in $frontmatterTools.GetEnumerator()) {
  if ($entry.Key -ne "delegation-supervisor" -and ($entry.Value -contains "delegate-agent")) {
    Add-CheckError("only delegation-supervisor may declare delegate-agent in agent frontmatter; found in $($entry.Key)")
  }
}

foreach ($entry in $matrixEntries.GetEnumerator()) {
  if (-not $frontmatterTools.ContainsKey($entry.Key)) {
    if ($agentsWithoutToolsList -contains $entry.Key) {
      Add-CheckError("$($entry.Key) agent is registered in agentCapabilityMatrix but declares no tools frontmatter list")
    } else {
      Add-CheckError("agentCapabilityMatrix entry has no agent file: $($entry.Key)")
    }
    continue
  }
  $declaredTools = @()
  $unknownTools = @()
  foreach ($toolProperty in @($entry.Value.tools.PSObject.Properties)) {
    if ($toolProperty.Value -ne $true) { continue }
    if ($toolDefinitionNames -contains $toolProperty.Name) {
      $declaredTools += $toolProperty.Name
    } else {
      $unknownTools += $toolProperty.Name
    }
  }
  if ($unknownTools.Count -gt 0) {
    Add-CheckError("$($entry.Key) agentCapabilityMatrix enables tools that are absent from toolDefinitions: $((@($unknownTools | Sort-Object)) -join ', ')")
  }
  $matrixTools = @($frontmatterTools[$entry.Key])
  $missingTool = $declaredTools | Where-Object { $matrixTools -notcontains $_ }
  $extraTool = $matrixTools | Where-Object { $declaredTools -notcontains $_ }
  if ($missingTool -or $extraTool) {
    Add-CheckError("$($entry.Key) frontmatter tools do not match agentCapabilityMatrix tools: frontmatter $((@($matrixTools | Sort-Object)) -join ', '), matrix $((@($declaredTools | Sort-Object)) -join ', ')")
  }
}

foreach ($entry in $frontmatterTools.GetEnumerator()) {
  if (($entry.Value -contains "delegate-agent") -and ($allowList -contains $entry.Key)) {
    Add-CheckError("specialist allow-list must not list the delegation-capable agent $($entry.Key)")
  }
}

# The hook-inheritance precondition withholds a capability rather than blocking
# enablement, so it needs a delegation surface it can withhold *to*. If an edit
# leaves every allow-listed agent able to mutate state, the capability-scoped
# rule degrades into a total block that the runbook and ADR both say it is not.
# This proves the tier is defined, never that it was used.
$nonMutatingCapabilities = @("read", "search", "todo")
$nonMutatingTier = @()
foreach ($entry in $frontmatterTools.GetEnumerator()) {
  # -cnotcontains keeps the tier predicate case-sensitive, matching the set
  # membership the Bash twin uses, so a case-divergent tools list cannot be
  # classified as non-mutating on one platform and mutating on the other.
  if ($allowList -cnotcontains $entry.Key) { continue }
  $mutatingCapabilities = @($entry.Value | Where-Object { $nonMutatingCapabilities -cnotcontains $_ })
  if ($mutatingCapabilities.Count -eq 0) { $nonMutatingTier += $entry.Key }
}
if (@($nonMutatingTier).Count -eq 0) {
  Add-CheckError("specialist allow-list has no non-mutating tier: no allow-listed agent declares capabilities within read, search, todo, so an unverified hook-inheritance result would withhold delegation entirely instead of scoping it")
}

Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "delegation-supervisor" -Description "supervisor agent catalog entry"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "orchestration-coordinator" -Description "coordinator role distinction"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "Inputs for next agent" -Description "core handoff contract extension"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "Decision status" -Description "decision status field"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "overlay-only" -Description "overlay-only orchestration wording"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "prompt-level contract" -Description "prompt-level approval caveat in the agent catalog"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "supervisor-orchestration.md" -Description "supervisor runbook pointer from the agent catalog"

# The approval gate is a prompt-level contract, not enforcement. Guard the
# shipped governance text - the agent catalog, every agent file, and the role
# and scope intents in tool-access.json - against drifting back into an
# enforcement claim. A line is a claim when it names the boundary and uses an
# enforcement word without also negating it.
$governanceFiles = @(".github/AGENTS.md", ".github/roles/tool-access.json")
foreach ($agentFile in $agentFiles) { $governanceFiles += ".github/agents/$($agentFile.Name)" }
foreach ($governanceFile in $governanceFiles) {
  $governancePath = Join-Path $RepoRoot $governanceFile
  if (-not (Test-Path $governancePath)) { continue }
  $lineNumber = 0
  foreach ($line in @(Get-Content -Path $governancePath)) {
    $lineNumber++
    if ($line -match "high-risk approval|approval boundary") {
      if (($line -match "enforc\w*") -and ($line -notmatch "not enforc|non-enforc|no enforc|rather than enforc|instead of enforc")) {
        Add-CheckError("$governanceFile`:$lineNumber must not describe the supervisor approval gate as enforcement")
      }
    }
  }
}

Assert-FileContains -RelativePath "docs/runbooks/agentic-dev.md" -Pattern "Supervisor delegation flow" -Description "supervisor delegation flow guidance"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "orchestration-policy.json" -Description "canonical policy reference"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "Prompt-level contract, not enforcement" -Description "prompt-level contract caveat heading"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "guided delegation plan" -Description "fallback documentation"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "jsonschema|ajv-cli" -Description "schema validation note"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "negative fixtures" -Description "negative fixture coverage note"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "delegation-supervisor" -Description "ADR supervisor naming"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "orchestration-policy.json" -Description "ADR canonical policy source"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "Option C" -Description "ADR deferred option record"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "Enablement Preconditions" -Description "enablement precondition section"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "preToolUse" -Description "hook-inheritance precondition in the runbook"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "preToolUse" -Description "hook-inheritance precondition in the ADR"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "derived tier is non-empty" -Description "non-empty tier assertion in the runbook"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "derived tier is non-empty" -Description "non-empty tier assertion in the ADR"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "requires the validator to accept the result" -Description "tolerated-state positive fixture note in the runbook"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "requires the validator to accept the result" -Description "tolerated-state positive fixture note in the ADR"
Assert-FileContains -RelativePath ".github/scripts/check-starter-workflow.sh" -Pattern "check-supervisor-orchestration.sh" -Description "Bash workflow entry point registration"
Assert-FileContains -RelativePath ".github/scripts/check-starter-workflow.ps1" -Pattern "check-supervisor-orchestration.ps1" -Description "PowerShell workflow entry point registration"
Assert-FileContains -RelativePath ".github/scripts/check-agent-contracts.sh" -Pattern "delegation-supervisor.agent.md" -Description "Bash agent contract registration"
Assert-FileContains -RelativePath ".github/scripts/check-agent-contracts.ps1" -Pattern "delegation-supervisor.agent.md" -Description "PowerShell agent contract registration"

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
      $path = Join-Path $Target ".github/AGENTS.md"
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
    & pwsh -NoProfile -File $PSCommandPath -RepoRoot $Target *> $logPath
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

if ($env:SUPERVISOR_SKIP_FIXTURES -ne "1") {
  $baselineRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("sov-fixture-" + [guid]::NewGuid().ToString("N"))
  Copy-FixtureRoot -Target $baselineRoot
  $baseline = Invoke-FixtureValidator -Target $baselineRoot
  if ($baseline.Status -ne 0) {
    Add-CheckError("Negative fixture baseline failed: the copied repository state does not pass the validator")
  }
  Remove-Item -Path $baselineRoot -Recurse -Force -ErrorAction SilentlyContinue

  Test-NegativeFixture -Mutation "enabled-by-default" -Description "the overlay is enabled by default (defaultEnabled != false)" -Expected "must be default-disabled"
  Test-NegativeFixture -Mutation "second-delegation-owner" -Description "a capability-matrix entry for an agent other than the supervisor declares delegate-agent" -Expected "only delegation-supervisor may hold delegate-agent"
  Test-NegativeFixture -Mutation "worker-role-delegation" -Description "a second role declares delegate-agent" -Expected "only the orchestration role may hold delegate-agent"
  Test-NegativeFixture -Mutation "frontmatter-divergence" -Description "the supervisor frontmatter diverges from the orchestration role" -Expected "frontmatter tools must be exactly"
  Test-NegativeFixture -Mutation "write-delegation-without-write-set" -Description "a write delegation omits its declared write set" -Expected "missing required property 'writeSet'"
  Test-NegativeFixture -Mutation "unbounded-write-set" -Description "a write delegation declares an unbounded write set" -Expected "declares an unbounded indicator"
  Test-NegativeFixture -Mutation "enforcement-overclaim" -Description "the agent catalog describes the approval gate as enforcement" -Expected "must not describe the supervisor approval gate as enforcement"
  Test-NegativeFixture -Mutation "worker-frontmatter-delegation" -Description "a non-supervisor agent file declares delegate-agent in its own frontmatter" -Expected "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  Test-NegativeFixture -Mutation "unregistered-delegation-holder" -Description "an agent file declares delegate-agent while escaping the capability matrix" -Expected "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  Test-NegativeFixture -Mutation "allow-list-delegation-holder" -Description "the specialist allow-list lists a delegation-capable agent" -Expected "specialist allow-list must not list the delegation-capable agent"
  Test-NegativeFixture -Mutation "frontmatter-matrix-mismatch" -Description "an agent's frontmatter tools diverge from its capability-matrix entry" -Expected "frontmatter tools do not match agentCapabilityMatrix tools"
  Test-NegativeFixture -Mutation "role-hint-mismatch" -Description "an agentRoleHints entry disagrees with the capability-matrix role" -Expected "agentRoleHints entry disagrees with agentCapabilityMatrix role"
  Test-NegativeFixture -Mutation "matrix-entry-without-agent-file" -Description "a capability-matrix entry has no agent file" -Expected "agentCapabilityMatrix entry has no agent file"
  Test-NegativeFixture -Mutation "registered-agent-without-tools-list" -Description "a registered agent file declares no tools frontmatter list" -Expected "declares no tools frontmatter list"
  Test-NegativeFixture -Mutation "matrix-tool-absent-from-tool-definitions" -Description "a capability-matrix entry enables a tool absent from toolDefinitions" -Expected "absent from toolDefinitions"
  Test-NegativeFixture -Mutation "enforcement-wording-in-agent-file" -Description "an agent file describes the approval gate as enforcement" -Expected "must not describe the supervisor approval gate as enforcement"
  Test-NegativeFixture -Mutation "empty-non-mutating-tier" -Description "every allow-listed agent gains a mutating capability, emptying the non-mutating tier" -Expected "specialist allow-list has no non-mutating tier"
  Test-PositiveFixture -Mutation "allow-listed-agent-without-matrix-entry" -Description "an allow-listed non-mutating agent file has no agentCapabilityMatrix entry"
} else {
  # SEC-1: never let a fixture-suite bypass pass unannounced. This mode is used by
  # the fixture re-entry child, but any wrapper, Makefile target, or CI `env:` block
  # can set it, so the skip is surfaced instead of silently zeroing the assertions.
  Write-Warning "SUPERVISOR_SKIP_FIXTURES=1 is set: the fixture suite was skipped, so this run asserted only the static checks."
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Supervisor orchestration overlay check passed."
exit 0
