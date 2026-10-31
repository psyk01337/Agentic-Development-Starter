$ErrorActionPreference = "Continue"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$stateDir = Join-Path $repoRoot ".agentic\state"
$enginePath = Join-Path $repoRoot ".github\scripts\agentic_engine.py"

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

$stdin = ""
if ([Console]::IsInputRedirected) {
  try {
    $stdin = [Console]::In.ReadToEnd()
  } catch {
    $stdin = ""
  }
}

# No tracked run means no loop to keep alive. Without this guard the hook would
# run on every turn end in every repository that uses the starter.
if (-not (Test-Path $stateDir -PathType Container) -or -not (Test-Path $enginePath -PathType Leaf)) {
  exit 0
}

$pythonExe = Find-UsablePython
if (-not $pythonExe) {
  [Console]::Error.WriteLine("[WARN] agent stop check skipped: no working Python interpreter")
  exit 0
}

# A failure here must never trap the turn. Exiting non-zero or emitting
# unparseable output would either deny work or loop the agent, so the fallback
# is always "allow the stop".
try {
  $output = $stdin | & $pythonExe $enginePath check-stop 2>&1
  $exitCode = $LASTEXITCODE
} catch {
  [Console]::Error.WriteLine("[WARN] agent stop check failed; allowing the stop")
  exit 0
}

if ($exitCode -ne 0) {
  [Console]::Error.WriteLine("[WARN] agent stop check failed; allowing the stop")
  exit 0
}

$text = ($output | Out-String).Trim()
if ($text -match '"decision"\s*:\s*"block"') {
  Write-Output $text
}

exit 0
