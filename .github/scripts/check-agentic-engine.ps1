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

$engine = Join-Path $RepoRoot ".github/scripts/agentic_engine.py"
$policy = Join-Path $RepoRoot ".github/roles/orchestration-policy.json"
$example = Join-Path $RepoRoot ".github/examples/agentic-engine/simple-feature-task.json"
$gitignore = Join-Path $RepoRoot ".gitignore"

if (-not (Test-Path $engine)) { Add-CheckError("Missing engine: .github/scripts/agentic_engine.py") }
if (-not (Test-Path $example)) { Add-CheckError("Missing example task: .github/examples/agentic-engine/simple-feature-task.json") }

if (Test-Path $policy) {
  $data = Get-Content -Path $policy -Raw | ConvertFrom-Json
  $retry = $data.retryPolicy
  if ($null -eq $retry) {
    Add-CheckError("orchestration-policy.json must contain a retryPolicy object")
  } else {
    $maxRepair = 0
    if (-not [int]::TryParse([string]$retry.maxRepairAttempts, [ref]$maxRepair) -or $maxRepair -lt 1 -or $maxRepair -gt 10) {
      Add-CheckError("retryPolicy.maxRepairAttempts must be an integer between 1 and 10")
    }
    $threshold = 0
    if (-not [int]::TryParse([string]$retry.identicalFailureThreshold, [ref]$threshold) -or $threshold -lt 1 -or $threshold -gt 5) {
      Add-CheckError("retryPolicy.identicalFailureThreshold must be an integer between 1 and 5")
    }
    if ($maxRepair -ge 1 -and $threshold -ge 1 -and $threshold -gt $maxRepair) {
      Add-CheckError("retryPolicy.identicalFailureThreshold must not exceed maxRepairAttempts")
    }
    $maxVerify = 0
    if (-not [int]::TryParse([string]$retry.maxVerifyRetries, [ref]$maxVerify) -or $maxVerify -lt 0 -or $maxVerify -gt 3) {
      Add-CheckError("retryPolicy.maxVerifyRetries must be an integer between 0 and 3")
    }
    foreach ($flag in @("escalateOnIdenticalFailure", "escalateOnBudgetExhausted", "inconclusiveIsNeverSuccess")) {
      if ($retry.$flag -ne $true) { Add-CheckError("retryPolicy.$flag must be true") }
    }
    if ($retry.stateLocation -ne ".agentic/state/<run-id>.json") {
      Add-CheckError("retryPolicy.stateLocation must be .agentic/state/<run-id>.json")
    }
  }
}

if ((Test-Path $gitignore) -and -not ((Get-Content -Path $gitignore -Raw) -match "\.agentic/state/")) {
  Add-CheckError(".gitignore must ignore .agentic/state/")
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) { Write-Error $message }
  exit 1
}

$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) { $python = Get-Command py -ErrorAction SilentlyContinue }
if ($null -eq $python) {
  Write-Error "No Python interpreter available for the agentic engine checks"
  exit 1
}

& $python.Source $engine selftest *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Error "agentic_engine.py selftest failed"
  exit 1
}

$stateDir = Join-Path ([System.IO.Path]::GetTempPath()) ("agentic-engine-check-" + [guid]::NewGuid().ToString("N"))
try {
  $output = & $python.Source $engine init --run-id check-fixture --task $example --repo-root $RepoRoot --state-dir $stateDir 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Engine rejected the shipped example task"
    exit 1
  }
  if (($output -join "`n") -notmatch '"stage": "implement"') {
    Write-Error "Engine did not start the example task at the implement stage"
    exit 1
  }
} finally {
  Remove-Item -Path $stateDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Agentic engine checks passed."
exit 0
