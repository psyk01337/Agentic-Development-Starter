param(
  [string]$ToolName = "",
  [string]$Action = "",
  [string]$Result = "",
  [string]$SessionId = ""
)

if ([Console]::IsInputRedirected) {
  try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($ToolName) -and $payload.toolName) {
      $ToolName = [string]$payload.toolName
    }
    if ([string]::IsNullOrWhiteSpace($SessionId) -and $payload.sessionId) {
      $SessionId = [string]$payload.sessionId
    }
    if ([string]::IsNullOrWhiteSpace($Action) -and $null -ne $payload.toolArgs) {
      $Action = ($payload.toolArgs | ConvertTo-Json -Compress -Depth 5)
    }
  } catch {
  }
}

# Audit records must never carry credentials, so secret-shaped values are
# redacted and the preview is truncated before anything is written to disk.
if (-not [string]::IsNullOrWhiteSpace($Action)) {
  $Action = $Action -replace '(sk-[A-Za-z0-9]{8,}|ghp_[A-Za-z0-9]{8,}|github_pat_[A-Za-z0-9_]{8,}|akia[0-9a-z]{16}|(?i)(token|secret|password|api[_-]?key|client_secret)\s*[=:]\s*"[^"]*")', '[REDACTED]'
  if ($Action.Length -gt 160) {
    $Action = $Action.Substring(0, 160) + "..."
  }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$logDir = if (-not [string]::IsNullOrWhiteSpace($env:HOOK_LOG_DIR)) { $env:HOOK_LOG_DIR } else { Join-Path $repoRoot ".github\hooks\logs" }
$logPath = Join-Path $logDir "agent-audit.log"

if (-not (Test-Path $logDir)) {
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($SessionId)) {
  $SessionId = "unknown"
}

if ([string]::IsNullOrWhiteSpace($Result)) {
  $Result = "unknown"
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
