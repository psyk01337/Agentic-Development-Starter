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

$requiredPrompts = @()
$manifestPath = Join-Path $RepoRoot ".github\starter-modules.json"
if (-not (Test-Path $manifestPath)) {
  Add-CheckError("Missing required file: .github/starter-modules.json")
} else {
  $manifestContent = Get-Content -Path $manifestPath -Raw
  $promptMatches = [regex]::Matches($manifestContent, '"\.github/prompts/[^"\s]+\.prompt\.md"')
  $requiredPrompts = @($promptMatches | ForEach-Object { $_.Value.Trim('"') } | Sort-Object -Unique)
}

foreach ($relativePath in $requiredPrompts) {
  $fullPath = Join-Path $RepoRoot $relativePath
  if (-not (Test-Path $fullPath)) {
    Add-CheckError("Missing prompt file: $relativePath")
    continue
  }

  $content = Get-Content -Path $fullPath -Raw
  $normalizedContent = $content -replace "`r", ""
  foreach ($heading in @("Context To Inspect First", "Deliverables", "Safety Boundaries", "Expected Output")) {
    if ($normalizedContent -notmatch "(?m)^## $([regex]::Escape($heading))$") {
      Add-CheckError("Prompt is missing heading '$heading': $relativePath")
    }
  }

  if ($normalizedContent -notmatch "(?i)stop and ask before") {
    Add-CheckError("Prompt must include destructive-change stop rule: $relativePath")
  }
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Prompt contract checks passed."
exit 0