param()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$errors = New-Object System.Collections.Generic.List[string]

function Add-CheckError([string]$Message) {
  $script:errors.Add($Message)
}

$requiredFiles = @(
  "README.md",
  "tasks/simple-bugfix.md",
  "tasks/add-api-endpoint.md",
  "tasks/frontend-component.md",
  "tasks/security-review.md",
  "tasks/update-docs-and-changelog.md",
  "tasks/debug-failing-ci.md",
  "tasks/problem-structuring.md",
  "expected/simple-bugfix.checklist.md",
  "expected/add-api-endpoint.checklist.md",
  "expected/frontend-component.checklist.md",
  "expected/security-review.checklist.md",
  "expected/problem-structuring.checklist.md"
)

foreach ($relativePath in $requiredFiles) {
  if (-not (Test-Path (Join-Path $scriptDir $relativePath))) {
    Add-CheckError("Missing eval file: evals/$relativePath")
  }
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Eval harness structure is present. Available tasks:"
Get-ChildItem -Path (Join-Path $scriptDir "tasks") -Filter "*.md" | Sort-Object Name | ForEach-Object { "tasks/$($_.Name)" }
exit 0