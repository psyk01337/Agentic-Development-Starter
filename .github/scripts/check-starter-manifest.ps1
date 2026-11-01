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

$manifestPath = Join-Path $RepoRoot ".github/starter-modules.json"
if (-not (Test-Path $manifestPath)) {
  Add-CheckError("Missing required file: .github/starter-modules.json")
} else {
  try {
    $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
  } catch {
    Add-CheckError("starter-modules.json is not valid JSON: $($_.Exception.Message)")
  }

  if ($manifest) {
    if (-not $manifest.modules -or $manifest.modules.Count -eq 0) {
      Add-CheckError("starter-modules.json must contain a non-empty modules array")
    }

    # The versioning guide requires semantic X.Y.Z and a major bump whenever a
    # module loses a file path, including a rename. Nothing enforced the shape,
    # so two-part versions drifted in unnoticed.
    $manifestVersion = $manifest.version
    if (-not ($manifestVersion -is [string]) -or $manifestVersion -cnotmatch '^\d+\.\d+\.\d+$') {
      Add-CheckError("starter-modules.json version must be semantic X.Y.Z; found '$manifestVersion'")
    }
    elseif ($manifestVersion -eq "0.0.0") {
      Add-CheckError("starter-modules.json version must not stay at 0.0.0")
    }
    else {
      # The guide also requires a changelog entry for every manifest change. A
      # bump with no recorded entry is untraceable, and that is the one part of
      # the versioning contract a stateless check can actually hold: whether a
      # bump was warranted cannot be known without the previous manifest, but
      # whether the current version is documented can.
      $changelogPath = Join-Path $RepoRoot "CHANGELOG.md"
      if (Test-Path -Path $changelogPath -PathType Leaf) {
        $changelogText = Get-Content -Path $changelogPath -Raw
        # Scope the search to Summary lines. A substring match over the whole
        # file is satisfied by the version being quoted anywhere, including in a
        # validation note about this very check, which makes the rule
        # unfalsifiable.
        #
        # The guards below have to survive prose. The first version of this used
        # (?![\d.]) and so rejected "at version 1.0.0." -- the most natural way to
        # end the sentence -- while accepting "1.0.0-beta", which is a different
        # version. A gate that turns on punctuation is arbitrary, and this one
        # failed the documented initialization path because of a full stop.
        $versionPattern = "(?m)^- Summary:.*(?<![\d.])" + [regex]::Escape($manifestVersion) + "(?![0-9A-Za-z])(?!\.[0-9])(?!-[0-9A-Za-z])(?!\+[0-9A-Za-z])"
        if ($changelogText -notmatch $versionPattern) {
          Add-CheckError("starter-modules.json version $manifestVersion is not recorded in a CHANGELOG.md Summary line; describe the manifest change there")
        }
      }
    }

    $seenIds = @{}
    $seenFiles = @{}
    $requiredCoreFiles = @(
      ".github/copilot-instructions.md",
      ".github/instructions/core.instructions.md",
      ".github/instructions/security.instructions.md",
      ".github/instructions/memory.instructions.md",
      ".github/starter-modules.json"
    )

    foreach ($module in $manifest.modules) {
      if ([string]::IsNullOrWhiteSpace($module.id)) {
        Add-CheckError("Module is missing id")
      } elseif ($seenIds.ContainsKey($module.id)) {
        Add-CheckError("Duplicate module id: $($module.id)")
      } else {
        $seenIds[$module.id] = $true
      }

      if (@("core", "optional", "overlay") -notcontains $module.kind) {
        Add-CheckError("Module $($module.id) has invalid kind")
      }

      if ($module.defaultEnabled -isnot [bool]) {
        Add-CheckError("Module $($module.id) must set boolean defaultEnabled")
      }

      if (-not $module.files -or $module.files.Count -eq 0) {
        Add-CheckError("Module $($module.id) must contain non-empty files")
        continue
      }

      foreach ($relativePath in $module.files) {
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
          Add-CheckError("Module $($module.id) contains an invalid file path")
          continue
        }

        $seenFiles[$relativePath] = $true
        if (-not (Test-Path (Join-Path $RepoRoot $relativePath))) {
          Add-CheckError("Manifest-listed file does not exist: $relativePath")
        }
      }
    }

    foreach ($relativePath in $seenFiles.Keys) {
      if ($relativePath -notlike "*.instructions.md") { continue }
      $instructionPath = Join-Path $RepoRoot $relativePath
      if (-not (Test-Path $instructionPath)) { continue }
      $content = Get-Content -Path $instructionPath -Raw
      if (-not $content.StartsWith("---")) {
        Add-CheckError("Instruction file must start with YAML frontmatter: $relativePath")
        continue
      }
      $closing = $content.IndexOf("---", 3)
      $frontmatter = if ($closing -gt 0) { $content.Substring(0, $closing) } else { "" }
      if ($frontmatter -notmatch "(?m)^applyTo:") {
        Add-CheckError("Instruction file is missing applyTo: $relativePath")
      }
    }

    # The manifest above is checked manifest-to-disk. Without the reverse
    # direction a new asset simply never ships when its module is adopted, and
    # nothing notices: four ADRs and the runbook index were missing this way.
    #
    # The reverse scan only makes sense in the repository that maintains the
    # starter. An adopting repository legitimately owns files in these
    # directories, so running the scan there would report the adopter's own
    # ADRs, runbooks, and agents as violations. maintainerAssetScan is that
    # switch: true in the starter, false in an adopting repo. It is required
    # rather than defaulted so neither case is silent.
    $scanSetting = $manifest.maintainerAssetScan
    if (-not ($scanSetting -is [bool])) {
      Add-CheckError("starter-modules.json must set maintainerAssetScan to true (starter) or false (adopting repository)")
    }
    elseif ($scanSetting) {
      $assetDirs = @(
        ".github/agents",
        ".github/prompts",
        ".github/skills",
        ".github/instructions",
        ".github/schema",
        ".github/examples",
        ".github/scripts",
        ".github/roles",
        ".github/hooks",
        ".github/workflows",
        ".vscode",
        "docs/adr",
        "docs/runbooks",
        "evals/tasks",
        "evals/expected"
      )
      $generatedMarkers = @("__pycache__", ".pytest_cache", ".mypy_cache")
      foreach ($assetDir in $assetDirs) {
        $base = Join-Path $RepoRoot $assetDir
        if (-not (Test-Path -Path $base -PathType Container)) { continue }
        foreach ($file in Get-ChildItem -Path $base -Recurse -File) {
          $relativePath = [System.IO.Path]::GetRelativePath($RepoRoot, $file.FullName).Replace('\', '/')
          $skip = $false
          foreach ($marker in $generatedMarkers) {
            if ($relativePath -like "*$marker*") { $skip = $true; break }
          }
          if ($skip) { continue }
          if ($relativePath -like ".github/hooks/logs/*") { continue }
          if (-not $seenFiles.ContainsKey($relativePath)) {
            Add-CheckError("Asset is not listed in starter-modules.json: $relativePath")
          }
        }
      }

      # The README states this repository's size in fourteen places and every one was
      # typed by hand. Nothing derived them, so the engine-test badge read 62 while the
      # suite ran 156 and the module count was off by one in two places. A count nobody
      # checks is a comment, so each claim below is compared with the tree that produces
      # it. Same switch as the scan above: these numbers describe the starter's own
      # README, which an adopting repository replaces.
      $readmePath = Join-Path $RepoRoot "README.md"
      if (Test-Path -Path $readmePath -PathType Leaf) {
        $readme = Get-Content -Path $readmePath -Raw
        $instructionDir = Join-Path $RepoRoot ".github/instructions"
        $skillsDir = Join-Path $RepoRoot ".github/skills"
        $enginePath = Join-Path $RepoRoot ".github/scripts/agentic_engine.py"
        $derived = @{
          instructions = @(Get-ChildItem -Path $instructionDir -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
          skills       = @(Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }).Count
          agents       = @(Get-ChildItem -Path (Join-Path $RepoRoot ".github/agents") -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
          prompts      = @(Get-ChildItem -Path (Join-Path $RepoRoot ".github/prompts") -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
          evals        = @(Get-ChildItem -Path (Join-Path $RepoRoot "evals/tasks") -File -ErrorAction SilentlyContinue).Count
          # The umbrella runs the others, so it is not one of the contracts.
          checks       = @(Get-ChildItem -Path (Join-Path $RepoRoot ".github/scripts") -Filter "check-*.sh" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "check-starter-workflow.sh" }).Count
          modules      = @($manifest.modules).Count
          engine       = if (Test-Path -Path $enginePath -PathType Leaf) { @(Select-String -Path $enginePath -Pattern '^\s+def test_').Count } else { 0 }
        }

        $claims = @(
          @{ Label = "skills badge"; Key = "skills"; Pattern = 'skills-(\d+)-blue' },
          @{ Label = "agents badge"; Key = "agents"; Pattern = 'agents-(\d+)-blue' },
          @{ Label = "prompts badge"; Key = "prompts"; Pattern = 'prompts-(\d+)-blue' },
          @{ Label = "checks badge"; Key = "checks"; Pattern = 'checks-(\d+)%2F\d+' },
          @{ Label = "engine-test badge"; Key = "engine"; Pattern = 'engine%20tests-(\d+)-' },
          @{ Label = "instructions table row"; Key = "instructions"; Pattern = '\|\s*\*\*Instructions\*\*\s*\|\s*(\d+)\s*\|' },
          @{ Label = "skills table row"; Key = "skills"; Pattern = '\|\s*\*\*Skills\*\*\s*\|\s*(\d+)\s*\|' },
          @{ Label = "agents table row"; Key = "agents"; Pattern = '\|\s*\*\*Agents\*\*\s*\|\s*(\d+)\s*\|' },
          @{ Label = "prompts table row"; Key = "prompts"; Pattern = '\|\s*\*\*Prompts\*\*\s*\|\s*(\d+)\s*\|' },
          @{ Label = "evals table row"; Key = "evals"; Pattern = '\|\s*\*\*Evals\*\*\s*\|\s*(\d+)\s*\|' },
          @{ Label = "guardrails table row"; Key = "checks"; Pattern = '\|\s*\*\*Guardrails\*\*\s*\|\s*(\d+) checks' },
          @{ Label = "module count in the manifest paragraph"; Key = "modules"; Pattern = '(\d+) modules across core, optional, and overlay' },
          @{ Label = "module count in the directory tree"; Key = "modules"; Pattern = 'what ships enabled \((\d+) modules\)' },
          @{ Label = "self-test count in the loop paragraph"; Key = "engine"; Pattern = 'state machine with (\d+) self-tests' }
        )
        foreach ($claim in $claims) {
          $match = [regex]::Match($readme, $claim.Pattern)
          if (-not $match.Success) {
            # A wording change is not a failure of the repository, but it is a lost
            # assertion. Say so rather than passing silently.
            Add-CheckError("README.md no longer states the $($claim.Label) in the expected form; update this check with the new wording instead of dropping it")
            continue
          }
          $claimed = [int]$match.Groups[1].Value
          if ($claimed -ne $derived[$claim.Key]) {
            Add-CheckError("README.md $($claim.Label) says $claimed; the repository has $($derived[$claim.Key])")
          }
        }
      }
    }

    # app/README.md states that until its verification block is replaced it describes a
    # scaffold rather than a project. Nothing read that sentence, so an app folder full of
    # code could keep pointing at a placeholder command while every gate reported green.
    #
    # The rule fires on a state transition rather than on a declaration, because a declared
    # "initialized: true" can be wrong and a folder's contents cannot. The starter itself is
    # unaffected: its app folder holds only that README, so the rule never reaches it.
    $appDir = Join-Path $RepoRoot "app"
    $appReadmePath = Join-Path $appDir "README.md"
    $appPlaceholder = "<the command that runs this project's tests>"
    if ((Test-Path -Path $appDir -PathType Container) -and (Test-Path -Path $appReadmePath -PathType Leaf)) {
      $appReadmeFull = (Resolve-Path $appReadmePath).Path
      $appCode = @(Get-ChildItem -Path $appDir -Recurse -File | Where-Object { $_.FullName -ne $appReadmeFull })
      if ($appCode.Count -gt 0) {
        $appText = Get-Content -Path $appReadmePath -Raw
        if ($appText.Contains($appPlaceholder)) {
          Add-CheckError("app/README.md still carries the placeholder verification command while app/ holds $($appCode.Count) file(s) of code; replace it with the command the tests actually run, so verify has something real to execute")
        }
      }
    }

    # docs/prd.md ships as a template whose provenance row reads `docs/inputs/<intake>.md`.
    # Nothing read that row either, so a project could route an intake, leave the PRD as a
    # template, and still pass every gate with a template as its stated source of truth.
    #
    # The trigger is derived from the row rather than from a flag: a template keeps a
    # placeholder in its Source field and a routed PRD names a document, so the difference is
    # observable. That also survives deferral, because a document the router declined never
    # reaches the row.
    $prdPath = Join-Path $RepoRoot "docs/prd.md"
    if (Test-Path -Path $prdPath -PathType Leaf) {
      $prdText = Get-Content -Path $prdPath -Raw
      $sourceRow = [regex]::Match($prdText, "(?m)^\|\s*Source\s*\|\s*(.+?)\s*\|\s*$")
      if ($sourceRow.Success) {
        $sourceValue = $sourceRow.Groups[1].Value.Trim().Trim('`').Trim()
        if (-not $sourceValue.Contains("<")) {
          if ($sourceValue.Contains("/") -or $sourceValue.ToLowerInvariant().EndsWith(".md")) {
            $candidates = @(
              (Join-Path $RepoRoot $sourceValue),
              (Join-Path (Join-Path (Join-Path $RepoRoot "docs") "inputs") $sourceValue)
            )
            $found = $false
            foreach ($candidate in $candidates) {
              if (Test-Path -Path $candidate -PathType Leaf) { $found = $true; break }
            }
            if (-not $found) {
              Add-CheckError("docs/prd.md names its source as '$sourceValue', but that file exists neither at that path nor under docs/inputs/")
            }
          }
          $remaining = [regex]::Matches($prdText, "<[^<>\n]+>")
          if ($remaining.Count -gt 0) {
            Add-CheckError("docs/prd.md names a concrete source but still contains template placeholders such as '$($remaining[0].Value)'; fill them in, or put the Source row back to the template value if nothing has been routed yet")
          }
        }
      }
    }

    # docs/inputs.md is the intake index: the router is meant to record every document it
    # routes. Nothing compared it with the directory, so a document could sit in
    # docs/inputs/ unread while every gate passed -- which is precisely what "I handed this
    # repository a PRD and got nothing back" looks like from the inside.
    #
    # The rule points one way on purpose: every intake must be acknowledged in the index. The
    # reverse, an index row naming a file that is gone, is deliberately not asserted, because
    # the shipped rows are fictional examples and exempting them by name would open a hole a
    # real document could be renamed into.
    $inputsDir = Join-Path $RepoRoot "docs/inputs"
    $inputsIndex = Join-Path $RepoRoot "docs/inputs.md"
    if ((Test-Path -Path $inputsDir -PathType Container) -and (Test-Path -Path $inputsIndex -PathType Leaf)) {
      $indexText = Get-Content -Path $inputsIndex -Raw
      # A plain substring test is not enough: the index mentions `docs/design-brief.md`, so an
      # intake called `brief.md` appeared logged when it was not. The lookarounds keep a name
      # from matching inside a longer one.
      $unlogged = @(
        Get-ChildItem -Path $inputsDir -File |
          Where-Object {
            $_.Name -ne "README.md" -and
            -not [regex]::IsMatch($indexText, "(?<![\w.-])" + [regex]::Escape($_.Name) + "(?![\w.-])")
          } |
          ForEach-Object { $_.Name } |
          Sort-Object
      )
      if ($unlogged.Count -gt 0) {
        Add-CheckError("docs/inputs/ holds intake document(s) that docs/inputs.md never mentions: $($unlogged -join ', '); route them with route-project-inputs so the decision is recorded")
      }
    }

    # The umbrella holds a hand-written list of the checks it runs, and nothing compared that
    # list with the scripts on disk. A thirteenth check could be added, registered, documented,
    # and never executed -- the repository's own line is that a guardrail nobody checks is a
    # comment, and this was the one place that could come true without anyone noticing.
    #
    # Each twin is checked against its own umbrella, because a PowerShell wrapper cannot run a
    # bash script. An absent umbrella is skipped rather than reported here; the asset scan and
    # the required-core list already own that failure.
    foreach ($twin in @(".ps1", ".sh")) {
      $umbrellaPath = Join-Path $RepoRoot ".github/scripts/check-starter-workflow$twin"
      if (-not (Test-Path -Path $umbrellaPath -PathType Leaf)) { continue }
      $umbrellaText = Get-Content -Path $umbrellaPath -Raw
      $scripts = @(Get-ChildItem -Path (Join-Path $RepoRoot ".github/scripts") -File -Filter "check-*$twin" |
        Where-Object { $_.Name -ne "check-starter-workflow$twin" })

      # An empty script exits 0, so the umbrella reports green while running nothing. This was not
      # hypothetical: a bad edit truncated check-agentic-engine.sh to zero bytes and the umbrella
      # passed it until the file was restored from git.
      $empty = @($scripts | Where-Object { $_.Length -lt 100 } | ForEach-Object { $_.Name } | Sort-Object)
      if ($empty.Count -gt 0) {
        Add-CheckError("$($empty -join ', ') are effectively empty; a script with no body exits 0 and passes every umbrella while checking nothing")
      }

      $unwired = @(
        $scripts |
          Where-Object { -not $umbrellaText.Contains($_.Name) } |
          ForEach-Object { $_.Name } |
          Sort-Object
      )
      if ($unwired.Count -gt 0) {
        Add-CheckError("$($unwired -join ', ') exist but check-starter-workflow$twin never runs them; a check nobody runs is a comment")
      }
    }

    foreach ($relativePath in $requiredCoreFiles) {
      if (-not $seenFiles.ContainsKey($relativePath)) {
        Add-CheckError("Required core file is not listed in starter-modules.json: $relativePath")
      }
    }
  }
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Starter manifest check passed."
exit 0