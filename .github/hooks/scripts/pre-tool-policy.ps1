param(
  [string]$ToolName = "",
  [string]$Action = "",
  [string]$Command = ""
)

$stdin = ""
try {
  $stdin = [Console]::In.ReadToEnd()
} catch {
  $stdin = ""
}

$candidate = ($ToolName + " " + $Action + " " + $Command + " " + $stdin).Trim()
$candidateLower = $candidate.ToLowerInvariant()

$rules = @(
  @{ Pattern = "(^|\s)rm\s+-rf(\s|$)"; Reason = "Destructive recursive delete is blocked."; Safer = "Use targeted file deletion with explicit paths and code review." },
  @{ Pattern = "(^|\s)del\s+/s\s+/q(\s|$)"; Reason = "Silent recursive delete is blocked."; Safer = "Use Remove-Item with explicit files and -WhatIf first." },
  @{ Pattern = "curl\s+[^\n\r|]*\|\s*(bash|sh)"; Reason = "Piped remote script execution is blocked."; Safer = "Download script, inspect it, then run with explicit checksum verification." },
  @{ Pattern = "(invoke-webrequest|irm|curl)\s+[^\n\r|;]*\|\s*(invoke-expression|iex)"; Reason = "Remote content execution via Invoke-Expression is blocked."; Safer = "Save remote content to a file, inspect, and run only trusted code." },
  @{ Pattern = "\.env[^\n\r]*(sk-[a-z0-9]{20,}|ghp_[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----|token\s*=\s*[^\s]+)"; Reason = "Potential real secret write to .env is blocked."; Safer = "Use placeholder values and inject real secrets through secure environment management." }
)

foreach ($rule in $rules) {
  if ($candidateLower -match $rule.Pattern) {
    Write-Error "[BLOCKED] $($rule.Reason)"
    Write-Host "Safer alternative: $($rule.Safer)"
    exit 1
  }
}

exit 0
