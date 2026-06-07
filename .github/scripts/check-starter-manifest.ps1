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