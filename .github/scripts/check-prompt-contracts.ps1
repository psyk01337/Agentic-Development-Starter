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

$requiredPrompts = @(
  ".github/prompts/onboard-existing-repo.prompt.md",
  ".github/prompts/plan-small-feature.prompt.md",
  ".github/prompts/implement-small-diff.prompt.md",
  ".github/prompts/review-current-diff.prompt.md",
  ".github/prompts/create-adr.prompt.md",
  ".github/prompts/generate-test-plan.prompt.md",
  ".github/prompts/prepare-release-notes.prompt.md",
  ".github/prompts/migrate-to-starter.prompt.md",
  ".github/prompts/security-review.prompt.md",
  ".github/prompts/debug-failing-ci.prompt.md"
)

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

  if ($normalizedContent -notmatch "(?i)stop and ask before destructive changes") {
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