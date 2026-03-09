param(
  [string]$RepoRoot = ""
)

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
} else {
  $RepoRoot = Resolve-Path $RepoRoot
}

$scripts = @(
  ".github/scripts/check-starter-skills.ps1",
  ".github/scripts/check-approval-gated-orchestration.ps1"
)

$failures = New-Object System.Collections.Generic.List[string]

foreach ($scriptPath in $scripts) {
  $fullPath = Join-Path $RepoRoot $scriptPath
  if (-not (Test-Path $fullPath)) {
    $failures.Add("Missing check script: $scriptPath")
    continue
  }

  & $fullPath -RepoRoot $RepoRoot
  if ($LASTEXITCODE -ne 0) {
    $failures.Add("Check failed: $scriptPath")
  }
}

if ($failures.Count -gt 0) {
  foreach ($failure in $failures) {
    Write-Error $failure
  }
  exit 1
}

Write-Host "Starter workflow checks passed."
exit 0