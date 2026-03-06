param(
  [string]$SessionId = "",
  [string]$UserName = ""
)

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

Write-Host "=== Agentic Session Guardrails Enabled ==="
Write-Host "Session: $SessionId"
Write-Host "Policy : .github/hooks/agent-policy.json"
Write-Host "Audit  : .github/hooks/logs/agent-audit.log"
Write-Host "No secrets, no destructive commands, no unsafe remote execution."
