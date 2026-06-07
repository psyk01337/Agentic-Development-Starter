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

$requiredFiles = @(
  "evals/README.md",
  "evals/tasks/simple-bugfix.md",
  "evals/tasks/add-api-endpoint.md",
  "evals/tasks/frontend-component.md",
  "evals/tasks/security-review.md",
  "evals/tasks/update-docs-and-changelog.md",
  "evals/tasks/debug-failing-ci.md",
  "evals/expected/simple-bugfix.checklist.md",
  "evals/expected/add-api-endpoint.checklist.md",
  "evals/expected/frontend-component.checklist.md",
  "evals/expected/security-review.checklist.md",
  "evals/run-evals.sh",
  "evals/run-evals.ps1"
)

foreach ($relativePath in $requiredFiles) {
  if (-not (Test-Path (Join-Path $RepoRoot $relativePath))) {
    Add-CheckError("Missing eval harness file: $relativePath")
  }
}

$readmePath = Join-Path $RepoRoot "evals\README.md"
if ((Test-Path $readmePath) -and (Get-Content -Path $readmePath -Raw) -notlike "*manual/semi-automated*") {
  Add-CheckError("Eval README must document the manual/semi-automated harness model.")
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Eval harness checks passed."
exit 0