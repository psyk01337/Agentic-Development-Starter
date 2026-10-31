param(
  [string]$SessionId = "",
  [string]$UserName = ""
)

if ([Console]::IsInputRedirected) {
  try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($SessionId) -and $payload.sessionId) {
      $SessionId = [string]$payload.sessionId
    }
  } catch {
  }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$logDir = Join-Path $repoRoot ".github\hooks\logs"
$logPath = Join-Path $logDir "session.log"

if (-not (Test-Path $logDir)) {
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($SessionId)) {
  $SessionId = [guid]::NewGuid().ToString()
}
if ([string]::IsNullOrWhiteSpace($UserName)) {
  $UserName = $env:USERNAME
}

$now = (Get-Date).ToString("o")
$entry = @{ timestamp = $now; event = "sessionStart"; sessionId = $SessionId; user = $UserName } | ConvertTo-Json -Compress
Add-Content -Path $logPath -Value $entry

# stdout is parsed as hook output, so the banner goes to stderr. Write-Host
# writes to the host and cannot be relied on to stay off stdout.
$banner = @(
  "=== Agentic Session Guardrails Enabled ==="
  "Session: $SessionId"
  "Policy : .github/hooks/agent-policy.json"
  "Rules  : .github/hooks/policy-rules.tsv"
  "Audit  : .github/hooks/logs/agent-audit.log"
  "No secrets, no destructive commands, no unsafe remote execution."
)
[Console]::Error.WriteLine(($banner -join [Environment]::NewLine))

# Inject the engine's stage context so the agent starts knowing where it is
# instead of discovering it on the first refused turn end. Only a top-level
# `additionalContext` is consumed for sessionStart; a wrapped field is ignored.
$stateDir = if (-not [string]::IsNullOrWhiteSpace($env:AGENTIC_STATE_DIR)) { $env:AGENTIC_STATE_DIR } else { Join-Path $repoRoot ".agentic\state" }
$enginePath = Join-Path $repoRoot ".github\scripts\agentic_engine.py"

if ((Test-Path $stateDir -PathType Container) -and (Test-Path $enginePath -PathType Leaf)) {
  $pythonExe = $null
  foreach ($name in @("python3", "python")) {
    foreach ($candidate in @(Get-Command $name -CommandType Application -ErrorAction SilentlyContinue)) {
      try {
        $probe = & $candidate.Source --version 2>&1
        if ($LASTEXITCODE -eq 0 -and (($probe | Out-String).Trim()) -match '^Python \d+\.') {
          $pythonExe = $candidate.Source
          break
        }
      } catch { continue }
    }
    if ($pythonExe) { break }
  }

  if ($pythonExe) {
    try {
      $context = (& $pythonExe $enginePath active-context --state-dir $stateDir 2>$null | Out-String).Trim()
      if ($context.StartsWith("{")) { Write-Output $context }
    } catch {
    }
  }
}

exit 0
