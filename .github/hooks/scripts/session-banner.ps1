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

exit 0
