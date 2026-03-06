param(
  [string]$ToolName = "",
  [string]$Action = "",
  [string]$Result = "",
  [string]$SessionId = ""
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$logDir = Join-Path $repoRoot ".github\hooks\logs"
$logPath = Join-Path $logDir "agent-audit.log"

if (-not (Test-Path $logDir)) {
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($SessionId)) {
  $SessionId = "unknown"
}

$entry = @{
  timestamp = (Get-Date).ToString("o")
  event = "postToolUse"
  sessionId = $SessionId
  tool = $ToolName
  action = $Action
  result = $Result
} | ConvertTo-Json -Compress

Add-Content -Path $logPath -Value $entry
Write-Host "Audit logged: $ToolName ($Action)"
