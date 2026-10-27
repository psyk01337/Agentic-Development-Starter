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
        if ($propertyNames -cnotcontains $name) {
          $problems.Add("${Path}: missing required property '$name'")
        }
      }
    }

    $additionalKeyword = $Schema.PSObject.Properties['additionalProperties']
    if ($null -ne $additionalKeyword -and $additionalKeyword.Value -eq $false) {
      foreach ($name in $propertyNames) {
        if ($declaredNames -cnotcontains $name) {
          $problems.Add("${Path}: unexpected property '$name'")
        }
      }
    }

    foreach ($name in $propertyNames) {
      if ($declaredNames -ccontains $name) {
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
  if ($null -ne $enumKeyword -and @($enumKeyword.Value) -cnotcontains $Instance) {
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
  $drift = @(@($schemaAllowList | Where-Object { $policyAllowList -cnotcontains $_ }) + @($policyAllowList | Where-Object { $schemaAllowList -cnotcontains $_ }))
  if ($drift.Count -gt 0) {
    $problems.Add("delegation-plan.schema.json agent enum has drifted from the canonical policy allow-list")
  }

  return $problems.ToArray()
}

$requiredFiles = @(
  ".github/agents/delegation-supervisor.agent.md",
  ".github/skills/supervisor-orchestration/SKILL.md",
  ".github/skills/verification-evidence-loop/SKILL.md",
  ".github/skills/adversarial-review/SKILL.md",
  ".github/skills/arena-bakeoff/SKILL.md",
  ".github/skills/swarm/SKILL.md",
  ".github/skills/prose-cleanup/SKILL.md",
  ".github/skills/session-compaction/SKILL.md",
  ".github/skills/decision-trail/SKILL.md",
  ".github/roles/orchestration-policy.json",
  ".github/schema/delegation-plan.schema.json",
  ".github/examples/supervisor-orchestration/complex-feature-delegation-plan.json",
  ".github/schema/delegation-result.schema.json",
  ".github/examples/supervisor-orchestration/simple-bugfix-delegation-result.json",
  ".github/scripts/check-supervisor-orchestration.ps1",
  ".github/scripts/check-supervisor-orchestration.sh",
  ".github/scripts/lib/supervisor-fixtures.sh",
  ".github/scripts/lib/supervisor-fixtures.ps1",
  "docs/runbooks/supervisor-orchestration.md",
  "docs/runbooks/engineering-team.md",
  "docs/runbooks/agentic-engine.md",
  ".github/skills/repair-loop/SKILL.md",
  "docs/adr/0003-supervisor-orchestration-overlay.md"
)

foreach ($relativePath in $requiredFiles) {
  Assert-FileExists -RelativePath $relativePath
}

$expectedRoleTools = @("read", "search", "todo", "delegate-agent")
$toolDefinitionNames = @()
$matrixEntries = @{}
$allowList = @()
$adapterTools = @()

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

  if (-not ($access.toolDefinitions.PSObject.Properties.Name -ccontains "delegate-agent")) {
    Add-CheckError("tool-access.json toolDefinitions is missing delegate-agent")
  }

  $roleNames = $access.roles.PSObject.Properties.Name
  if ($roleNames -cnotcontains "orchestration") {
    Add-CheckError("tool-access.json roles is missing the orchestration role")
  } else {
    $roleTools = @($access.roles.orchestration.tools)
    $missingRoleTool = $expectedRoleTools | Where-Object { $roleTools -cnotcontains $_ }
    $extraRoleTool = $roleTools | Where-Object { $expectedRoleTools -cnotcontains $_ }
    if ($missingRoleTool -or $extraRoleTool) {
      Add-CheckError("orchestration role tools must be exactly $($expectedRoleTools -join ', ')")
    }
    foreach ($forbidden in @("edit", "execute")) {
      if ($roleTools -ccontains $forbidden) {
        Add-CheckError("orchestration role must not include $forbidden")
      }
    }
  }

  $matrixNames = $access.agentCapabilityMatrix.PSObject.Properties.Name
  if ($matrixNames -cnotcontains "delegation-supervisor") {
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
    if ($role.Name -ne "orchestration" -and (@($role.Value.tools) -ccontains "delegate-agent")) {
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

  # The host adapter map is the canonical source for the platform delegation
  # vocabulary. The rule below derives the tool names it guards from this map
  # rather than from a hardcoded list, so adding a host is a data change. The
  # map is closed on two sides: it must not be empty, and no adapter name may
  # resolve to a mutating capability, or the map becomes a laundering route for
  # privileged tool names.
  $hostAdaptersProperty = $policy.delegationDepth.PSObject.Properties["hostAdapters"]
  if ($null -eq $hostAdaptersProperty -or $null -eq $hostAdaptersProperty.Value) {
    Add-CheckError("orchestration-policy.json must define a non-empty delegationDepth.hostAdapters map")
  } else {
    foreach ($hostProperty in @($hostAdaptersProperty.Value.PSObject.Properties)) {
      $adapter = $hostProperty.Value
      if ($adapter -isnot [System.Management.Automation.PSCustomObject]) {
        Add-CheckError("orchestration-policy.json hostAdapters entry for $($hostProperty.Name) must be an object")
        continue
      }
      $declaredToolsProperty = $adapter.PSObject.Properties["delegationTools"]
      if ($null -eq $declaredToolsProperty -or $declaredToolsProperty.Value -isnot [System.Array]) {
        Add-CheckError("orchestration-policy.json hostAdapters entry for $($hostProperty.Name) must declare a delegationTools list")
        continue
      }
      foreach ($tool in @($declaredToolsProperty.Value)) { $adapterTools += $tool }
    }
    $adapterTools = @($adapterTools | Sort-Object -Unique)
    if ($adapterTools.Count -eq 0) {
      Add-CheckError("orchestration-policy.json hostAdapters must declare at least one delegation tool name")
    }
    foreach ($adapterTool in $adapterTools) {
      # -ccontains keeps the mutating-capability membership case-sensitive,
      # matching the set membership the Bash twin uses.
      if (@("edit", "execute") -ccontains $adapterTool) {
        Add-CheckError("orchestration-policy.json hostAdapters must not map delegation to a mutating capability: $adapterTool")
      }
    }
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
    if ($allowList -cnotcontains $requiredAgent) {
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
    if ($categories -cnotcontains $requiredCategory) {
      Add-CheckError("approval-required categories are missing $requiredCategory")
    }
  }

  # ADR 0005 routing data. taskClasses owns playbook selection and is a closed,
  # ordered thirteen-class taxonomy; complexityRouting owns the simple/complex
  # escalation envelope and is pinned on its own; evidenceRequirements owns the
  # fixed result vocabulary, the completion rule, and the closed surface set.
  # None of these three keys was read by any check before ADR 0005 rollout slice 3.
  $expectedTaskClasses = @(
    "QUESTION", "INVESTIGATION", "BUG_FIX", "FEATURE", "REFACTOR", "ARCHITECTURE",
    "SECURITY", "PERFORMANCE", "TESTING", "DOCUMENTATION", "MIGRATION",
    "INFRASTRUCTURE", "UNKNOWN_COMPLEX"
  )
  $taskClassesProperty = $policy.PSObject.Properties["taskClasses"]
  $classIds = @()
  if ($null -eq $taskClassesProperty -or @($taskClassesProperty.Value).Count -eq 0) {
    Add-CheckError("orchestration-policy.json taskClasses must be a non-empty list")
  } else {
    foreach ($entry in @($taskClassesProperty.Value)) {
      $classId = [string]$entry.id
      if ([string]::IsNullOrWhiteSpace($classId)) {
        Add-CheckError("orchestration-policy.json taskClasses entries must declare a non-empty id")
        continue
      }
      $classIds += $classId
      if ([string]::IsNullOrWhiteSpace([string]$entry.description)) {
        Add-CheckError("orchestration-policy.json taskClasses entry $classId must declare a non-empty description")
      }
    }
    $missingClasses = @($expectedTaskClasses | Where-Object { $classIds -cnotcontains $_ })
    $extraClasses = @($classIds | Where-Object { $expectedTaskClasses -cnotcontains $_ })
    $duplicatedClasses = @($classIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($missingClasses.Count -gt 0) {
      Add-CheckError("orchestration-policy.json taskClasses are missing $($missingClasses -join ', ')")
    }
    if ($extraClasses.Count -gt 0) {
      Add-CheckError("orchestration-policy.json taskClasses contain unknown classes: $($extraClasses -join ', ')")
    }
    if ($duplicatedClasses.Count -gt 0) {
      Add-CheckError("orchestration-policy.json taskClasses repeat classes: $($duplicatedClasses -join ', ')")
    }
    if (($missingClasses.Count -eq 0) -and ($extraClasses.Count -eq 0) -and ($duplicatedClasses.Count -eq 0)) {
      if (($classIds -join ',') -cne ($expectedTaskClasses -join ',')) {
        Add-CheckError("orchestration-policy.json taskClasses must preserve the ordered thirteen-class taxonomy")
      }
    }
  }

  $playbooksProperty = $policy.PSObject.Properties["playbooks"]
  $allowedDelegates = @($allowList) + @("delegation-supervisor")
  if ($null -eq $playbooksProperty -or $null -eq $playbooksProperty.Value) {
    Add-CheckError("orchestration-policy.json playbooks must be an object")
  } else {
    $playbookClassIds = @($playbooksProperty.Value.PSObject.Properties.Name)
    $unknownClassIds = @($playbookClassIds | Where-Object { $expectedTaskClasses -cnotcontains $_ } | Sort-Object)
    if ($unknownClassIds.Count -gt 0) {
      Add-CheckError("orchestration-policy.json playbooks references an unknown class id: $($unknownClassIds -join ', ')")
    }
    foreach ($classId in $expectedTaskClasses) {
      if ($playbookClassIds -cnotcontains $classId) {
        Add-CheckError("orchestration-policy.json playbooks is missing a playbook for class $classId")
      }
    }
    foreach ($playbookProperty in @($playbooksProperty.Value.PSObject.Properties)) {
      $classId = $playbookProperty.Name
      $stages = @($playbookProperty.Value)
      if ($stages.Count -eq 0) {
        Add-CheckError("orchestration-policy.json playbook for $classId is empty")
        continue
      }
      $stageIndex = 0
      foreach ($stage in $stages) {
        if ([string]::IsNullOrWhiteSpace([string]$stage.id)) {
          Add-CheckError("orchestration-policy.json playbook stage $classId[$stageIndex] must declare a non-empty id")
        }
        if ([string]::IsNullOrWhiteSpace([string]$stage.name)) {
          Add-CheckError("orchestration-policy.json playbook stage $classId[$stageIndex] must declare a non-empty name")
        }
        if ($stage.skipRequiresReason -ne $true) {
          Add-CheckError("orchestration-policy.json playbook stage $classId[$stageIndex] must set skipRequiresReason to true")
        }
        $delegatesProperty = $stage.PSObject.Properties["delegatesTo"]
        if ($null -eq $delegatesProperty -or $delegatesProperty.Value -isnot [System.Array]) {
          Add-CheckError("orchestration-policy.json playbook stage $classId[$stageIndex] must declare delegatesTo as a list")
          $delegatesList = @()
          $delegatesNonEmpty = $false
        } else {
          $delegatesList = @($delegatesProperty.Value)
          $delegatesNonEmpty = ($delegatesList.Count -gt 0)
        }
        if ($delegatesNonEmpty -eq ($stage.requiresHumanApproval -eq $true)) {
          Add-CheckError("orchestration-policy.json playbook stage $classId[$stageIndex] must set exactly one of a non-empty delegatesTo and requiresHumanApproval: true")
        }
        foreach ($delegateName in $delegatesList) {
          if ($allowedDelegates -cnotcontains $delegateName) {
            Add-CheckError("orchestration-policy.json playbook stage $classId[$stageIndex] delegates to an agent outside the allow-list: $delegateName")
          }
        }
        $stageIndex++
      }
    }
  }

  $evidenceProperty = $policy.PSObject.Properties["evidenceRequirements"]
  $expectedSurfaces = @("ui", "api", "database", "cli", "configuration", "library")
  if ($null -eq $evidenceProperty -or $null -eq $evidenceProperty.Value) {
    Add-CheckError("orchestration-policy.json evidenceRequirements must be an object")
  } else {
    $evidence = $evidenceProperty.Value
    $expectedVocabulary = @("VERIFIED", "NOT_VERIFIED", "INCONCLUSIVE")
    $vocabularyProperty = $evidence.PSObject.Properties["resultVocabulary"]
    $vocabulary = @()
    if ($null -ne $vocabularyProperty) { $vocabulary = @($vocabularyProperty.Value) }
    if (($vocabulary -join '|') -cne ($expectedVocabulary -join '|')) {
      Add-CheckError("orchestration-policy.json evidenceRequirements.resultVocabulary must be exactly [VERIFIED, NOT_VERIFIED, INCONCLUSIVE]")
    }
    if ($evidence.inconclusiveNeverSuccess -ne $true) {
      Add-CheckError("orchestration-policy.json evidenceRequirements.inconclusiveNeverSuccess must be true")
    }
    if ($evidence.completionRule -cne "orchestrator-declared-after-verification-evidence") {
      Add-CheckError("orchestration-policy.json evidenceRequirements.completionRule must be 'orchestrator-declared-after-verification-evidence'")
    }
    $surfacesProperty = $evidence.PSObject.Properties["surfaces"]
    if ($null -eq $surfacesProperty -or $null -eq $surfacesProperty.Value) {
      Add-CheckError("orchestration-policy.json evidenceRequirements.surfaces must be an object")
    } else {
      $surfaceIds = @($surfacesProperty.Value.PSObject.Properties.Name)
      $unknownSurfaces = @($surfaceIds | Where-Object { $expectedSurfaces -cnotcontains $_ } | Sort-Object)
      if ($unknownSurfaces.Count -gt 0) {
        Add-CheckError("orchestration-policy.json evidenceRequirements.surfaces contains an unknown surface: $($unknownSurfaces -join ', ')")
      }
      foreach ($surfaceId in $expectedSurfaces) {
        if ($surfaceIds -cnotcontains $surfaceId) {
          Add-CheckError("orchestration-policy.json evidenceRequirements.surfaces is missing $surfaceId")
        }
      }
      foreach ($surfaceProperty in @($surfacesProperty.Value.PSObject.Properties)) {
        $surfaceId = $surfaceProperty.Name
        if ($expectedSurfaces -cnotcontains $surfaceId) { continue }
        $evidenceListProperty = $surfaceProperty.Value.PSObject.Properties["evidence"]
        if ($null -eq $evidenceListProperty -or @($evidenceListProperty.Value).Count -eq 0) {
          Add-CheckError("orchestration-policy.json evidenceRequirements surface $surfaceId must declare a non-empty evidence list")
          continue
        }
        $badKind = $false
        foreach ($item in @($evidenceListProperty.Value)) {
          if ([string]::IsNullOrWhiteSpace([string]$item)) { $badKind = $true; break }
        }
        if ($badKind) {
          Add-CheckError("orchestration-policy.json evidenceRequirements surface $surfaceId must declare non-empty string evidence kinds")
        }
      }
    }
  }

  # The complexityRouting pins promised by ADR 0005 rollout step 3. The key
  # shipped as unread data since v1.0; these checks make it data again.
  $complexity = $policy.complexityRouting
  if ($null -eq $complexity) {
    Add-CheckError("orchestration-policy.json complexityRouting.defaultWhenUncertain must be 'complex'")
    Add-CheckError("orchestration-policy.json complexityRouting.simpleWorkflow must be a non-empty string")
    Add-CheckError("orchestration-policy.json complexityRouting.complexWorkflow must be a non-empty string")
    Add-CheckError("orchestration-policy.json complexityRouting.complexIfAny must be a non-empty list")
    Add-CheckError("orchestration-policy.json complexityRouting.notBasedOn must be a non-empty list")
  } else {
    if ($complexity.defaultWhenUncertain -cne "complex") {
      Add-CheckError("orchestration-policy.json complexityRouting.defaultWhenUncertain must be 'complex'")
    }
    if ([string]::IsNullOrWhiteSpace([string]$complexity.simpleWorkflow)) {
      Add-CheckError("orchestration-policy.json complexityRouting.simpleWorkflow must be a non-empty string")
    }
    if ([string]::IsNullOrWhiteSpace([string]$complexity.complexWorkflow)) {
      Add-CheckError("orchestration-policy.json complexityRouting.complexWorkflow must be a non-empty string")
    }
    $complexIfAnyProperty = $complexity.PSObject.Properties["complexIfAny"]
    if ($null -eq $complexIfAnyProperty -or @($complexIfAnyProperty.Value).Count -eq 0) {
      Add-CheckError("orchestration-policy.json complexityRouting.complexIfAny must be a non-empty list")
    }
    $notBasedOnProperty = $complexity.PSObject.Properties["notBasedOn"]
    if ($null -eq $notBasedOnProperty -or @($notBasedOnProperty.Value).Count -eq 0) {
      Add-CheckError("orchestration-policy.json complexityRouting.notBasedOn must be a non-empty list")
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

    # ADR 0006 result contract: the worked example must validate, and the
    # schema's enums must resolve against the canonical policy data rather than
    # carry a second copy of the allow-list, the result vocabulary, or the
    # surface set.
    $resultSchema = Get-Content -Path (Join-Path $RepoRoot ".github/schema/delegation-result.schema.json") -Raw | ConvertFrom-Json
    $resultExample = Get-Content -Path (Join-Path $RepoRoot ".github/examples/supervisor-orchestration/simple-bugfix-delegation-result.json") -Raw | ConvertFrom-Json
    foreach ($problem in @(Get-SchemaInstanceProblems -Instance $resultExample -Schema $resultSchema)) {
      Add-CheckError($problem)
    }
    $resultAgentEnum = @($resultSchema.properties.agent.enum)
    $resultAgentDrift = @(@($resultAgentEnum | Where-Object { $allowList -cnotcontains $_ }) + @($allowList | Where-Object { $resultAgentEnum -cnotcontains $_ }))
    if ($resultAgentDrift.Count -gt 0) {
      Add-CheckError("delegation-result.schema.json agent enum has drifted from the canonical policy allow-list")
    }
    $resultVocabularyEnum = @($resultSchema.properties.verificationPerformed.items.properties.result.enum)
    $policyVocabulary = @($policy.evidenceRequirements.resultVocabulary)
    if (($resultVocabularyEnum -join '|') -cne ($policyVocabulary -join '|')) {
      Add-CheckError("delegation-result.schema.json result enum has drifted from the canonical evidence vocabulary")
    }
    $resultSurfaceEnum = @($resultSchema.properties.verificationPerformed.items.properties.surface.enum)
    $policySurfaces = @($policy.evidenceRequirements.surfaces.PSObject.Properties.Name)
    $resultSurfaceDrift = @(@($resultSurfaceEnum | Where-Object { $policySurfaces -cnotcontains $_ }) + @($policySurfaces | Where-Object { $resultSurfaceEnum -cnotcontains $_ }))
    if ($resultSurfaceDrift.Count -gt 0) {
      Add-CheckError("delegation-result.schema.json surface enum has drifted from the canonical evidence surfaces")
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

function Get-FrontmatterList([string]$AgentText, [string]$Key) {
  # Reads a frontmatter list key in either the inline form (`key: [a, b]`) or the
  # block form (`key:` followed by indented `- item` lines), because the platform
  # accepts either and a rule that reads only the inline form can be bypassed by
  # reformatting the same declaration. Returns $null when the key is absent.
  $inline = [regex]::Match($AgentText, "(?m)^$Key`:\s*\[([^\]]*)\]")
  if ($inline.Success) {
    return @(
      $inline.Groups[1].Value -split "," | ForEach-Object { $_.Trim().Trim("'`"") } | Where-Object { $_ }
    )
  }
  $block = [regex]::Match($AgentText, "(?m)^$Key`:\s*\r?\n((?:[ \t]+-[^\r\n]*\r?\n?)+)")
  if (-not $block.Success) { return $null }
  $items = @()
  foreach ($line in ($block.Groups[1].Value -split "\r?\n")) {
    $item = $line.Trim()
    if (-not $item.StartsWith("-")) { continue }
    $item = $item.Substring(1).Trim().Trim("'`"")
    if ($item) { $items += $item }
  }
  return @($items)
}

$frontmatterTools = @{}
$agentsWithoutToolsList = @()
foreach ($agentFile in $agentFiles) {
  $agentName = $agentFile.Name.Substring(0, $agentFile.Name.Length - ".agent.md".Length)
  $agentText = Get-Content -Path $agentFile.FullName -Raw
  $parsedTools = Get-FrontmatterList -AgentText $agentText -Key "tools"
  if ($null -eq $parsedTools) {
    # tools: is optional in .agent.md frontmatter, so an unregistered agent file
    # is not required to declare one. Only a registered capability boundary
    # makes the list load-bearing.
    $agentsWithoutToolsList += $agentName
    continue
  }
  $frontmatterTools[$agentName] = @($parsedTools)
}

# The platform delegation vocabulary comes from the hostAdapters map in
# orchestration-policy.json, loaded above, rather than from a hardcoded list.
$platformDelegationTools = @($adapterTools)
if ($frontmatterTools.ContainsKey('delegation-supervisor')) {
  $supervisorTools = @($frontmatterTools['delegation-supervisor'])
  if ($supervisorTools -cnotcontains "delegate-agent") {
    Add-CheckError("delegation-supervisor frontmatter must declare the delegate-agent capability")
  }
  $missingRoleTools = @($expectedRoleTools | Where-Object { $supervisorTools -cnotcontains $_ })
  if ($missingRoleTools.Count -gt 0) {
    Add-CheckError("delegation-supervisor frontmatter tools must include $((@($missingRoleTools | Sort-Object)) -join ', ')")
  }
  # Contains-plus-closed-adapter-allow-list: the holder may declare the
  # canonical capability plus host tool names from the adapter map, and
  # nothing else. The closed side is what keeps this weaker shape safe.
  $extraTools = @($supervisorTools | Where-Object { $expectedRoleTools -cnotcontains $_ -and $platformDelegationTools -cnotcontains $_ })
  if ($extraTools.Count -gt 0) {
    Add-CheckError("delegation-supervisor frontmatter declares tools outside the orchestration role and hostAdapters: $((@($extraTools | Sort-Object)) -join ', ')")
  }
}

foreach ($entry in $frontmatterTools.GetEnumerator()) {
  if ($entry.Key -ne "delegation-supervisor" -and ($entry.Value -ccontains "delegate-agent")) {
    Add-CheckError("only delegation-supervisor may declare delegate-agent in agent frontmatter; found in $($entry.Key)")
  }
}

# The same invariant over the host's own vocabulary. The repository names the
# capability `delegate-agent`, but a runtime expresses delegation with its own
# tool name and an agent allow-list key, so a rule keyed only to the repository's
# name would let a second delegation path in with every check still green. The
# vocabulary is derived from the hostAdapters map rather than hardcoded, so a
# host with a differently named primitive is covered by data instead of a code
# change.
$frontmatterSubagents = @{}
foreach ($agentFile in $agentFiles) {
  $agentName = $agentFile.Name.Substring(0, $agentFile.Name.Length - ".agent.md".Length)
  $agentText = Get-Content -Path $agentFile.FullName -Raw
  $parsedSubagents = Get-FrontmatterList -AgentText $agentText -Key "agents"
  if ($null -eq $parsedSubagents) { continue }
  $frontmatterSubagents[$agentName] = @($parsedSubagents)
}

foreach ($entry in $frontmatterTools.GetEnumerator()) {
  if ($entry.Key -eq "delegation-supervisor") { continue }
  # -ccontains keeps the adapter-vocabulary membership case-sensitive, matching
  # the set operations the Bash twin uses, so a case-variant adapter name such
  # as EDIT cannot collide with the repository's own `edit` tool on this twin.
  $platformDeclared = @($entry.Value | Where-Object { $platformDelegationTools -ccontains $_ })
  if ($platformDeclared.Count -gt 0) {
    Add-CheckError("only delegation-supervisor may declare a platform delegation tool in agent frontmatter; found $((@($platformDeclared | Sort-Object)) -join ', ') in $($entry.Key)")
  }
}

foreach ($entry in $frontmatterSubagents.GetEnumerator()) {
  if ($entry.Key -ne "delegation-supervisor") {
    Add-CheckError("only delegation-supervisor may declare an agent allow-list in agent frontmatter; found agents: in $($entry.Key)")
  }
}

if ($frontmatterSubagents.ContainsKey('delegation-supervisor')) {
  # -cnotcontains keeps the allow-list membership case-sensitive, matching the
  # tier predicate and the Bash twin.
  $offAllowList = @($frontmatterSubagents['delegation-supervisor'] | Where-Object { $allowList -cnotcontains $_ })
  if ($offAllowList.Count -gt 0) {
    Add-CheckError("delegation-supervisor agent allow-list must stay within the canonical specialistAllowList; found $((@($offAllowList | Sort-Object)) -join ', ')")
  }
}

# Pairing rules: the allow-list and the invocation path exist together or not
# at all. An allow-list nothing can invoke is a guardrail in appearance only,
# and an invocation path with no validated allow-list is the unscoped case.
$supervisorHostTools = @()
if ($frontmatterTools.ContainsKey('delegation-supervisor')) {
  $supervisorHostTools = @($frontmatterTools['delegation-supervisor'] | Where-Object { $platformDelegationTools -ccontains $_ })
}
$supervisorHasAgentsKey = $frontmatterSubagents.ContainsKey('delegation-supervisor')
if ($supervisorHasAgentsKey -and $supervisorHostTools.Count -eq 0) {
  Add-CheckError("delegation-supervisor declares an agents allow-list without a host delegation tool from hostAdapters")
}
if ($supervisorHostTools.Count -gt 0 -and -not $supervisorHasAgentsKey) {
  Add-CheckError("delegation-supervisor declares a host delegation tool without an agents allow-list")
}

foreach ($entry in $matrixEntries.GetEnumerator()) {
  if (-not $frontmatterTools.ContainsKey($entry.Key)) {
    if ($agentsWithoutToolsList -ccontains $entry.Key) {
      Add-CheckError("$($entry.Key) agent is registered in agentCapabilityMatrix but declares no tools frontmatter list")
    } else {
      Add-CheckError("agentCapabilityMatrix entry has no agent file: $($entry.Key)")
    }
    continue
  }
  $declaredTools = @()
  $unknownTools = @()
  $adapterToolsEnabled = @()
  foreach ($toolProperty in @($entry.Value.tools.PSObject.Properties)) {
    if ($toolProperty.Value -ne $true) { continue }
    if ($platformDelegationTools -ccontains $toolProperty.Name) {
      $adapterToolsEnabled += $toolProperty.Name
    } elseif ($toolDefinitionNames -ccontains $toolProperty.Name) {
      $declaredTools += $toolProperty.Name
    } else {
      $unknownTools += $toolProperty.Name
    }
  }
  if ($adapterToolsEnabled.Count -gt 0) {
    Add-CheckError("$($entry.Key) agentCapabilityMatrix must not enable host adapter tools: $((@($adapterToolsEnabled | Sort-Object)) -join ', ') (host tool names live in orchestration-policy.json hostAdapters)")
  }
  if ($unknownTools.Count -gt 0) {
    Add-CheckError("$($entry.Key) agentCapabilityMatrix enables tools that are absent from toolDefinitions: $((@($unknownTools | Sort-Object)) -join ', ')")
  }
  $matrixTools = @($frontmatterTools[$entry.Key] | Where-Object { $platformDelegationTools -cnotcontains $_ })
  $missingTool = $declaredTools | Where-Object { $matrixTools -cnotcontains $_ }
  $extraTool = $matrixTools | Where-Object { $declaredTools -cnotcontains $_ }
  if ($missingTool -or $extraTool) {
    Add-CheckError("$($entry.Key) frontmatter tools do not match agentCapabilityMatrix tools: frontmatter $((@($matrixTools | Sort-Object)) -join ', '), matrix $((@($declaredTools | Sort-Object)) -join ', ')")
  }
}

# Registration direction (ADR 0004 Phase 3): every agent file not on the
# specialist allow-list must carry both a capability-matrix entry and a role
# hint. The tolerance for an allow-listed non-mutating agent with no matrix
# entry stays in place, because the tier derives from frontmatter — a reason
# that exists only for allow-listed agents.
$roleHintNames = @()
if ($null -ne $access) { $roleHintNames = @($access.agentRoleHints.PSObject.Properties.Name) }
foreach ($agentFile in $agentFiles) {
  $agentName = $agentFile.Name.Substring(0, $agentFile.Name.Length - ".agent.md".Length)
  # -ccontains keeps the allow-list and registry membership case-sensitive,
  # matching the set membership the Bash twin uses.
  if ($allowList -ccontains $agentName) { continue }
  if (@($matrixEntries.Keys) -cnotcontains $agentName) {
    Add-CheckError("$agentName agent is not on the specialist allow-list and has no agentCapabilityMatrix entry")
  }
  if ($roleHintNames -cnotcontains $agentName) {
    Add-CheckError("$agentName agent is not on the specialist allow-list and has no agentRoleHints entry")
  }
}

foreach ($entry in $frontmatterTools.GetEnumerator()) {
  if (($entry.Value -ccontains "delegate-agent") -and ($allowList -ccontains $entry.Key)) {
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

Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "delegation-supervisor" -Description "supervisor agent catalog entry"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "orchestration-coordinator" -Description "coordinator role distinction"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "Inputs for next agent" -Description "core handoff contract extension"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "Decision status" -Description "decision status field"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "overlay-only" -Description "overlay-only orchestration wording"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "prompt-level contract" -Description "prompt-level approval caveat in the agent catalog"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "supervisor-orchestration.md" -Description "supervisor runbook pointer from the agent catalog"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "Treat a delegated subagent as stateless: it does not inherit the conversation history, cannot ask clarifying questions, and may not have todo or follow-up tools." -Description "delegated subagent statelessness rule"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "Return needs-clarification as a terminal result, not as a question that waits for an answer." -Description "delegated needs-clarification terminal rule"
Assert-FileContains -RelativePath ".github/agent-catalog.md" -Pattern "The guided handoff allow-list and the delegable subagent allow-list are different" -Description "guided versus delegable allow-list distinction"
Assert-FileContains -RelativePath "docs/runbooks/engineering-team.md" -Pattern "Treat a delegated subagent as stateless: it does not inherit the conversation history, cannot ask clarifying questions, and may not have todo or follow-up tools." -Description "engineering team runbook statelessness parity"

# The approval gate is a prompt-level contract, not enforcement. Guard the
# shipped governance text - the agent catalog, every agent file, and the role
# and scope intents in tool-access.json - against drifting back into an
# enforcement claim. A line is a claim when it names the boundary and uses an
# enforcement word without also negating it.
$governanceFiles = @(".github/agent-catalog.md", ".github/roles/tool-access.json")
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
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern "hostAdapters" -Description "host adapter map reference in the supervisor runbook"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "Amended by ADR 0004" -Description "ADR 0004 amendment pointer in ADR 0003"
Assert-FileContains -RelativePath "docs/runbooks/supervisor-orchestration.md" -Pattern 'must carry an `agentCapabilityMatrix` entry' -Description "registration rule note in the supervisor runbook"
Assert-FileContains -RelativePath "docs/adr/0003-supervisor-orchestration-overlay.md" -Pattern "Amended by ADR 0004 Phase 3" -Description "ADR 0004 Phase 3 amendment pointer in ADR 0003"
Assert-FileContains -RelativePath ".github/skills/verification-evidence-loop/SKILL.md" -Pattern "delegation-result.schema.json" -Description "verification skill result-contract reference"
Assert-FileContains -RelativePath ".github/skills/verification-evidence-loop/SKILL.md" -Pattern "is never a success" -Description "verification skill inconclusive-never-success rule"
Assert-FileContains -RelativePath ".github/skills/adversarial-review/SKILL.md" -Pattern "SEVERITY, LOCATION, CLAIM, EVIDENCE, FAILURE_SCENARIO, RECOMMENDED_ACTION" -Description "adversarial-review finding-format line"
Assert-FileContains -RelativePath ".github/skills/adversarial-review/SKILL.md" -Pattern "must deduplicate findings" -Description "adversarial-review deduplication rule"
Assert-FileContains -RelativePath ".github/skills/adversarial-review/SKILL.md" -Pattern "Evidence outranks voting" -Description "adversarial-review evidence-outranks-voting rule"
Assert-FileContains -RelativePath ".github/skills/arena-bakeoff/SKILL.md" -Pattern "must not modify the same working tree" -Description "arena-bakeoff candidate isolation rule"
Assert-FileContains -RelativePath ".github/skills/arena-bakeoff/SKILL.md" -Pattern "proposal or implementation, assumptions, tradeoffs, rejected alternatives, verification evidence" -Description "arena-bakeoff five-item candidate return"
Assert-FileContains -RelativePath ".github/skills/arena-bakeoff/SKILL.md" -Pattern "Never average incompatible architectures" -Description "arena-bakeoff never-average rule"
Assert-FileContains -RelativePath ".github/skills/swarm/SKILL.md" -Pattern "solve DIFFERENT independent slices concurrently" -Description "swarm definition rule"
Assert-FileContains -RelativePath ".github/skills/swarm/SKILL.md" -Pattern "Detect shared mutable state before parallel execution" -Description "swarm shared-state detection rule"
Assert-FileContains -RelativePath ".github/skills/swarm/SKILL.md" -Pattern "must not silently overwrite" -Description "swarm no-silent-overwrite rule"
Assert-FileContains -RelativePath ".github/skills/swarm/SKILL.md" -Pattern "Aggregate results only after all required slices finish" -Description "swarm aggregation rule"
Assert-FileContains -RelativePath ".github/skills/prose-cleanup/SKILL.md" -Pattern "This skill is NOT responsible for workflow-state storage" -Description "workflow-state boundary"
Assert-FileContains -RelativePath ".github/skills/prose-cleanup/SKILL.md" -Pattern "Preserve technical detail" -Description "technical-detail preservation"
Assert-FileContains -RelativePath ".github/skills/prose-cleanup/SKILL.md" -Pattern "writing-quality filter, not a context compressor" -Description "writing-quality vs context-compaction boundary"
Assert-FileContains -RelativePath ".github/skills/session-compaction/SKILL.md" -Pattern "Never discard unresolved risk or evidence necessary to continue safely" -Description "session-compaction never-discard-risk rule"
Assert-FileContains -RelativePath ".github/skills/session-compaction/SKILL.md" -Pattern "compact continuation brief" -Description "session-compaction brief phrase"
Assert-FileContains -RelativePath ".github/skills/session-compaction/SKILL.md" -Pattern "Discard conversational filler" -Description "session-compaction discard-filler rule"
Assert-FileContains -RelativePath ".github/skills/decision-trail/SKILL.md" -Pattern "Do NOT confuse decision history with workflow state" -Description "decision-trail workflow-state boundary"
Assert-FileContains -RelativePath ".github/skills/decision-trail/SKILL.md" -Pattern "Prefer pointers over long prose" -Description "decision-trail pointer-over-prose rule"
Assert-FileContains -RelativePath ".github/skills/decision-trail/SKILL.md" -Pattern "For trivial changes, do not create unnecessary logging artifacts" -Description "decision-trail trivial-changes rule"
Assert-FileContains -RelativePath ".github/scripts/check-starter-workflow.sh" -Pattern "check-supervisor-orchestration.sh" -Description "Bash workflow entry point registration"
Assert-FileContains -RelativePath ".github/scripts/check-starter-workflow.ps1" -Pattern "check-supervisor-orchestration.ps1" -Description "PowerShell workflow entry point registration"
Assert-FileContains -RelativePath ".github/scripts/check-agent-contracts.sh" -Pattern "delegation-supervisor.agent.md" -Description "Bash agent contract registration"
Assert-FileContains -RelativePath ".github/scripts/check-agent-contracts.ps1" -Pattern "delegation-supervisor.agent.md" -Description "PowerShell agent contract registration"

# Fixture machinery lives in lib/supervisor-fixtures.ps1 so the invariant body
# above stays reviewable. Dot-sourced here because it relies on Add-CheckError
# and $RepoRoot from this scope. $ValidatorPath is passed explicitly because
# $PSCommandPath inside a dot-sourced file points at that file, not at this one.
$ValidatorPath = $PSCommandPath
. (Join-Path $PSScriptRoot "lib/supervisor-fixtures.ps1")

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
  Test-NegativeFixture -Mutation "frontmatter-divergence" -Description "the supervisor frontmatter diverges from the orchestration role" -Expected "must declare the delegate-agent capability"
  Test-NegativeFixture -Mutation "write-delegation-without-write-set" -Description "a write delegation omits its declared write set" -Expected "missing required property 'writeSet'"
  Test-NegativeFixture -Mutation "unbounded-write-set" -Description "a write delegation declares an unbounded write set" -Expected "declares an unbounded indicator"
  Test-NegativeFixture -Mutation "enforcement-overclaim" -Description "the agent catalog describes the approval gate as enforcement" -Expected "must not describe the supervisor approval gate as enforcement"
  Test-NegativeFixture -Mutation "worker-frontmatter-delegation" -Description "a non-supervisor agent file declares delegate-agent in its own frontmatter" -Expected "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  Test-NegativeFixture -Mutation "unregistered-delegation-holder" -Description "an agent file declares delegate-agent while escaping the capability matrix" -Expected "only delegation-supervisor may declare delegate-agent in agent frontmatter"
  Test-NegativeFixture -Mutation "worker-agent-tool-delegation" -Description "a non-supervisor agent file declares a platform delegation tool in its own frontmatter" -Expected "only delegation-supervisor may declare a platform delegation tool in agent frontmatter"
  Test-NegativeFixture -Mutation "worker-agents-key-delegation" -Description "a non-supervisor agent file declares an agent allow-list in its own frontmatter" -Expected "only delegation-supervisor may declare an agent allow-list in agent frontmatter"
  Test-NegativeFixture -Mutation "supervisor-agents-key-off-allow-list" -Description "the supervisor agent allow-list names an agent outside the canonical allow-list" -Expected "agent allow-list must stay within the canonical specialistAllowList"
  Test-NegativeFixture -Mutation "supervisor-agents-without-host-tool" -Description "the supervisor declares an agents allow-list without a host delegation tool" -Expected "declares an agents allow-list without a host delegation tool"
  Test-NegativeFixture -Mutation "supervisor-host-tool-without-agents" -Description "the supervisor declares a host delegation tool without an agents allow-list" -Expected "declares a host delegation tool without an agents allow-list"
  Test-NegativeFixture -Mutation "adapter-mutating-capability" -Description "the host adapter map declares a tool name that resolves to a mutating capability" -Expected "must not map delegation to a mutating capability"
  Test-NegativeFixture -Mutation "supervisor-frontmatter-extra-tool" -Description "the supervisor frontmatter declares a tool outside the role and hostAdapters" -Expected "outside the orchestration role and hostAdapters"
  Test-NegativeFixture -Mutation "non-allow-listed-agent-without-matrix-entry" -Description "an agent file off the allow-list has no agentCapabilityMatrix entry" -Expected "is not on the specialist allow-list and has no agentCapabilityMatrix entry"
  Test-NegativeFixture -Mutation "non-allow-listed-agent-without-role-hint" -Description "an agent file off the allow-list has no agentRoleHints entry" -Expected "is not on the specialist allow-list and has no agentRoleHints entry"
  Test-NegativeFixture -Mutation "worker-block-style-tools-delegation" -Description "a non-supervisor agent file declares a platform delegation tool in block-style frontmatter" -Expected "only delegation-supervisor may declare a platform delegation tool in agent frontmatter"
  Test-NegativeFixture -Mutation "worker-block-style-agents-key-delegation" -Description "a non-supervisor agent file declares a block-style agent allow-list in its own frontmatter" -Expected "only delegation-supervisor may declare an agent allow-list in agent frontmatter"
  Test-NegativeFixture -Mutation "allow-list-delegation-holder" -Description "the specialist allow-list lists a delegation-capable agent" -Expected "specialist allow-list must not list the delegation-capable agent"
  Test-NegativeFixture -Mutation "frontmatter-matrix-mismatch" -Description "an agent's frontmatter tools diverge from its capability-matrix entry" -Expected "frontmatter tools do not match agentCapabilityMatrix tools"
  Test-NegativeFixture -Mutation "role-hint-mismatch" -Description "an agentRoleHints entry disagrees with the capability-matrix role" -Expected "agentRoleHints entry disagrees with agentCapabilityMatrix role"
  Test-NegativeFixture -Mutation "matrix-entry-without-agent-file" -Description "a capability-matrix entry has no agent file" -Expected "agentCapabilityMatrix entry has no agent file"
  Test-NegativeFixture -Mutation "registered-agent-without-tools-list" -Description "a registered agent file declares no tools frontmatter list" -Expected "declares no tools frontmatter list"
  Test-NegativeFixture -Mutation "matrix-tool-absent-from-tool-definitions" -Description "a capability-matrix entry enables a tool absent from toolDefinitions" -Expected "absent from toolDefinitions"
  Test-NegativeFixture -Mutation "adapter-enabled-in-capability-matrix" -Description "a capability-matrix entry enables a host adapter tool" -Expected "agentCapabilityMatrix must not enable host adapter tools"
  Test-NegativeFixture -Mutation "enforcement-wording-in-agent-file" -Description "an agent file describes the approval gate as enforcement" -Expected "must not describe the supervisor approval gate as enforcement"
  Test-NegativeFixture -Mutation "empty-non-mutating-tier" -Description "every allow-listed agent gains a mutating capability, emptying the non-mutating tier" -Expected "specialist allow-list has no non-mutating tier"
  Test-NegativeFixture -Mutation "removed-task-class" -Description "the policy drops a task class from the taxonomy" -Expected "taskClasses are missing QUESTION"
  Test-NegativeFixture -Mutation "empty-playbook" -Description "a playbook becomes an empty stage list" -Expected "playbook for DOCUMENTATION is empty"
  Test-NegativeFixture -Mutation "playbook-stage-off-allow-list" -Description "a playbook stage delegates to an agent outside the allow-list" -Expected "delegates to an agent outside the allow-list"
  Test-NegativeFixture -Mutation "playbook-stage-both-delegation-and-approval" -Description "a playbook stage sets both a non-empty delegatesTo and requiresHumanApproval" -Expected "must set exactly one of a non-empty delegatesTo and requiresHumanApproval"
  Test-NegativeFixture -Mutation "playbook-unknown-class-id" -Description "a playbook references an unknown class id" -Expected "playbooks references an unknown class id"
  Test-NegativeFixture -Mutation "mutated-evidence-vocabulary" -Description "the evidence result vocabulary is mutated" -Expected "evidenceRequirements.resultVocabulary"
  Test-NegativeFixture -Mutation "unknown-evidence-surface" -Description "an evidence surface outside the closed vocabulary appears" -Expected "contains an unknown surface"
  Test-NegativeFixture -Mutation "edited-completion-rule" -Description "the completion rule is edited" -Expected "evidenceRequirements.completionRule"
  Test-NegativeFixture -Mutation "complexity-default-not-complex" -Description "complexityRouting.defaultWhenUncertain changes from complex" -Expected "defaultWhenUncertain must be 'complex'"
  Test-NegativeFixture -Mutation "complexity-empty-simple-workflow" -Description "complexityRouting.simpleWorkflow becomes empty" -Expected "simpleWorkflow must be a non-empty string"
  Test-NegativeFixture -Mutation "complexity-empty-complex-workflow" -Description "complexityRouting.complexWorkflow becomes empty" -Expected "complexWorkflow must be a non-empty string"
  Test-NegativeFixture -Mutation "complexity-empty-complexIfAny" -Description "complexityRouting.complexIfAny becomes empty" -Expected "complexIfAny must be a non-empty list"
  Test-NegativeFixture -Mutation "complexity-empty-notBasedOn" -Description "complexityRouting.notBasedOn becomes empty" -Expected "notBasedOn must be a non-empty list"
  Test-NegativeFixture -Mutation "malformed-delegation-result" -Description "a delegation result omits its verification record" -Expected "missing required property 'verificationPerformed'"
  Test-PositiveFixture -Mutation "allow-listed-agent-without-matrix-entry" -Description "an allow-listed non-mutating agent file has no agentCapabilityMatrix entry"
  Test-PositiveFixture -Mutation "unsupported-host-empty-adapter-list" -Description "a host adapter entry records an unsupported host with an empty delegationTools list"
  Test-PositiveFixture -Mutation "adapter-case-variant-tool-name" -Description "a case-variant adapter tool name is accepted as a distinct non-mutating host name"
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
