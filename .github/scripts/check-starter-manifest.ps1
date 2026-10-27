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
    # Only directories that hold module assets are scanned, so root tooling
    # stays out of scope.
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