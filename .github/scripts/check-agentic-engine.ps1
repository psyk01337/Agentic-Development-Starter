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

  # This repository is a stack-agnostic boilerplate, so the shipped allowlist must not
  # quietly admit only one ecosystem. Each name below stands for a family a project could
  # legitimately choose; dropping one blocks that whole family from ever reaching VERIFIED,
  # and nothing else would notice.
  $verification = @($data.verificationCommands)
  $families = [ordered]@{
    node   = "JavaScript/TypeScript"
    python = "Python"
    go     = "Go"
    cargo  = "Rust"
    dotnet = ".NET"
    mvn    = "JVM"
    ruby   = "Ruby"
    php    = "PHP"
  }
  if ($verification.Count -eq 0) {
    Add-CheckError("orchestration-policy.json must declare a non-empty verificationCommands list")
  } else {
    $allowedNames = @($verification | ForEach-Object { ([string]$_).Trim().ToLowerInvariant() })
    foreach ($name in $families.Keys) {
      if ($allowedNames -notcontains $name) {
        Add-CheckError("verificationCommands no longer allows '$name' ($($families[$name])); a project on that stack could not reach VERIFIED")
      }
    }
  }

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

# The family guard above only fails when someone trims the allowlist, which never happens on a
# clean repository. Untested, it could be deleted and every contract would stay green while stack
# neutrality quietly stopped being enforced -- the thing this repository exists to protect.
#
# The fixture copies the tree, trims the allowlist, and requires the failure. AGENTIC_ENGINE_FIXTURE
# stops the copied check from running its own copy of this block, which would otherwise recurse
# until the disk filled.
if ($env:AGENTIC_ENGINE_FIXTURE -ne "1") {
  $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("engine-fixture-" + [guid]::NewGuid().ToString("N"))
  $fixtureTree = Join-Path $fixtureRoot "repo"
  New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null

  try {
    $excluded = @(".git", ".forlocal", ".agentic", "__pycache__")
    New-Item -ItemType Directory -Path $fixtureTree -Force | Out-Null
    Get-ChildItem -Path $RepoRoot -Force |
      Where-Object { $excluded -notcontains $_.Name } |
      ForEach-Object { Copy-Item -Path $_.FullName -Destination $fixtureTree -Recurse -Force }

    $policyPath = Join-Path $fixtureTree ".github/roles/orchestration-policy.json"
    $policy = Get-Content -Path $policyPath -Raw | ConvertFrom-Json
    $policy.verificationCommands = @("node", "python", "bash", "pwsh")
    [System.IO.File]::WriteAllText($policyPath, ($policy | ConvertTo-Json -Depth 20))

    $previousFixtureFlag = $env:AGENTIC_ENGINE_FIXTURE
    $env:AGENTIC_ENGINE_FIXTURE = "1"
    try {
      $fixtureOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixtureTree ".github/scripts/check-agentic-engine.ps1") -RepoRoot $fixtureTree 2>&1
      $fixtureExit = $LASTEXITCODE
    } finally {
      $env:AGENTIC_ENGINE_FIXTURE = $previousFixtureFlag
    }
    $fixtureText = ($fixtureOutput | Out-String)

    if ($fixtureExit -eq 0) {
      Add-CheckError("A trimmed verificationCommands list did not fail the engine check; the family guard is gone or no longer covers Go, Rust, .NET, JVM, Ruby, or PHP")
    } elseif (-not $fixtureText.Contains("no longer allows")) {
      Add-CheckError("The trimmed policy failed for the wrong reason: $($fixtureText.Trim().Split("`n")[0])")
    }
  } finally {
    Remove-Item -Path $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
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

$selftestOutput = & $python.Source $engine selftest 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Error "agentic_engine.py selftest failed"
  Write-Host ($selftestOutput -join "`n")
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
