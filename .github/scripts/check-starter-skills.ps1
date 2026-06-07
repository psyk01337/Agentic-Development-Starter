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
$manifestSkillPaths = @{}

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
    $manifestSkillPaths[$relativePath] = $true
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

$skillsRoot = Join-Path $RepoRoot ".github/skills"
if (-not (Test-Path $skillsRoot -PathType Container)) {
  Add-CheckError("Missing required directory: .github/skills")
} else {
  $skillDirectories = Get-ChildItem -Path $skillsRoot -Directory | Sort-Object Name
  foreach ($skillDirectory in $skillDirectories) {
    $skillName = $skillDirectory.Name
    $relativePath = ".github/skills/$skillName/SKILL.md"
    $skillFile = Join-Path $skillDirectory.FullName "SKILL.md"

    if ($skillName -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
      Add-CheckError("Skill directory must be lowercase hyphenated: .github/skills/$skillName")
    }

    if (-not (Test-Path $skillFile)) {
      Add-CheckError("Missing skill file: $relativePath")
      continue
    }

    if ((Test-Path $manifestPath) -and (-not $manifestSkillPaths.ContainsKey($relativePath))) {
      Add-CheckError("Skill file is not referenced in starter-modules.json: $relativePath")
    }

    $lines = Get-Content -Path $skillFile
    if ($lines.Count -eq 0 -or $lines[0] -ne "---") {
      Add-CheckError("Skill file must start with YAML frontmatter: $relativePath")
      continue
    }

    $frontmatter = @{}
    for ($index = 1; $index -lt $lines.Count; $index++) {
      if ($lines[$index] -eq "---") {
        break
      }

      if ($lines[$index] -match "^([^:]+):\s*(.+)$") {
        $frontmatter[$Matches[1]] = $Matches[2]
      }
    }

    if (-not $frontmatter.ContainsKey("name")) {
      Add-CheckError("Skill frontmatter is missing name: $relativePath")
    } elseif ($frontmatter["name"] -notmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
      Add-CheckError("Skill frontmatter name must be lowercase hyphenated: $relativePath")
    } elseif ($frontmatter["name"] -ne $skillName) {
      Add-CheckError("Skill frontmatter name must match directory name: $relativePath")
    }

    if (-not $frontmatter.ContainsKey("description") -or [string]::IsNullOrWhiteSpace($frontmatter["description"])) {
      Add-CheckError("Skill frontmatter is missing description: $relativePath")
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