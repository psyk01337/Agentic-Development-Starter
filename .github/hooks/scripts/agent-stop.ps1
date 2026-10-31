$ErrorActionPreference = "Continue"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$stateDir = if (-not [string]::IsNullOrWhiteSpace($env:AGENTIC_STATE_DIR)) { $env:AGENTIC_STATE_DIR } else { Join-Path $repoRoot ".agentic\state" }
$enginePath = Join-Path $repoRoot ".github\scripts\agentic_engine.py"
$logDir = Join-Path $repoRoot ".github\hooks\logs"

# Being on PATH is not the same as working. Windows ships a python3.exe App
# Execution Alias that is a stub which fails at runtime, and Get-Command returns
# every match as an array, so candidates are flattened and probed one by one.
function Find-UsablePython {
  foreach ($name in @("python3", "python")) {
    foreach ($candidate in @(Get-Command $name -CommandType Application -ErrorAction SilentlyContinue)) {
      try {
        $version = & $candidate.Source --version 2>&1
        if ($LASTEXITCODE -eq 0 -and (($version | Out-String).Trim()) -match '^Python \d+\.') {
          return $candidate.Source
        }
      } catch {
        continue
      }
    }
  }
  return $null
}

# The event must be recorded even when no run is armed, otherwise "the hook never
# fired" and "the hook fired and its decision was ignored" look identical.
function Write-Trace([string]$Decision, [bool]$Armed) {
  try {
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $active = $script:stdin -match '"stop_hook_active"\s*:\s*true'
    $entry = @{
      at             = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
      event          = "agentStop"
      armed          = $Armed
      stopHookActive = [bool]$active
      decision       = $Decision
    } | ConvertTo-Json -Compress
    Add-Content -Path (Join-Path $logDir "agent-stop.log") -Value $entry -ErrorAction SilentlyContinue
  } catch {
  }
}

$stdin = ""
if ([Console]::IsInputRedirected) {
  try {
    $stdin = [Console]::In.ReadToEnd()
  } catch {
    $stdin = ""
  }
}

if (-not (Test-Path $stateDir -PathType Container) -or -not (Test-Path $enginePath -PathType Leaf)) {
  Write-Trace -Decision "skipped" -Armed $false
  exit 0
}

$pythonExe = Find-UsablePython
if (-not $pythonExe) {
  [Console]::Error.WriteLine("[WARN] agent stop check skipped: no working Python interpreter")
  Write-Trace -Decision "skipped-no-python" -Armed $true
  exit 0
}

$output = ""
$exitCode = 0
try {
  $output = $stdin | & $pythonExe $enginePath check-stop --state-dir $stateDir 2>$null
  $exitCode = $LASTEXITCODE
} catch {
  $exitCode = 1
}

if ($exitCode -ne 0) {
  [Console]::Error.WriteLine("[WARN] agent stop check failed; allowing the stop")
  Write-Trace -Decision "error" -Armed $true
  exit 0
}

$text = ($output | Out-String).Trim()
if ($text -match '"decision"\s*:\s*"block"') {
  Write-Output $text
  Write-Trace -Decision "block" -Armed $true
} else {
  Write-Trace -Decision "allow" -Armed $true
}

exit 0