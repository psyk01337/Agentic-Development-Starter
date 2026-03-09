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
  $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
  $skillPaths = @()

  foreach ($module in $manifest.modules) {
    foreach ($filePath in $module.files) {
      if ($filePath -like ".github/skills/*/SKILL.md") {
        $skillPaths += $filePath
      }
    }
  }

  $uniqueSkillPaths = $skillPaths | Sort-Object -Unique
  foreach ($relativePath in $uniqueSkillPaths) {
    $fullPath = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path $fullPath)) {
      Add-CheckError("Missing manifest-listed skill file: $relativePath")
      continue
    }

    $skillDirectory = Split-Path -Path $fullPath -Parent
    if (-not (Test-Path $skillDirectory -PathType Container)) {
      Add-CheckError("Missing skill directory for: $relativePath")
    }

    $skillFileName = Split-Path -Path $fullPath -Leaf
    if ($skillFileName -ne "SKILL.md") {
      Add-CheckError("Unexpected skill file name for: $relativePath")
    }
  }
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Starter skill manifest check passed."
exit 0