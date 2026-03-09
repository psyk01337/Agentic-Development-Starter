param(
  [string]$ToolName = "",
  [string]$Action = "",
  [string]$Command = ""
)

function Get-DefaultRules {
  return @(
    @{ Pattern = "(^|\s)rm\s+-rf(\s|$)"; Reason = "Destructive recursive delete is blocked."; Safer = "Use targeted file deletion with explicit paths and code review." },
    @{ Pattern = "(^|\s)del\s+/s\s+/q(\s|$)"; Reason = "Silent recursive delete is blocked."; Safer = "Use Remove-Item with explicit files and -WhatIf first." },
    @{ Pattern = "curl\s+[^\n\r|]*\|\s*(bash|sh)"; Reason = "Piped remote script execution is blocked."; Safer = "Download script, inspect it, then run with explicit checksum verification." },
    @{ Pattern = "(invoke-webrequest|irm|curl)\s+[^\n\r|;]*\|\s*(invoke-expression|iex)"; Reason = "Remote content execution via Invoke-Expression is blocked."; Safer = "Save remote content to a file, inspect it, and run only trusted code." },
    @{ Pattern = "\.env[^\n\r]*(sk-[a-z0-9]{20,}|ghp_[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----|token\s*=\s*[^\s]+)"; Reason = "Potential real secret write to .env is blocked."; Safer = "Use placeholder values and inject real secrets through secure environment management." }
  )
}

function Get-PolicyRules([string]$RepoRoot) {
  $rulesPath = Join-Path $RepoRoot ".github\hooks\policy-rules.tsv"
  if (-not (Test-Path $rulesPath)) {
    return Get-DefaultRules
  }

  $parsedRules = @()
  foreach ($line in Get-Content -Path $rulesPath) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
      continue
    }

    $parts = $line -split "`t", 3
    if ($parts.Count -lt 3) {
      continue
    }

    $parsedRules += @{
      Pattern = $parts[0]
      Reason = $parts[1]
      Safer = $parts[2]
    }
  }

  if ($parsedRules.Count -eq 0) {
    return Get-DefaultRules
  }

  return $parsedRules
}

$stdin = ""
try {
  $stdin = [Console]::In.ReadToEnd()
} catch {
  $stdin = ""
}

$candidate = ($ToolName + " " + $Action + " " + $Command + " " + $stdin).Trim()
$candidateLower = $candidate.ToLowerInvariant()

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$rules = Get-PolicyRules -RepoRoot $repoRoot

foreach ($rule in $rules) {
  if ($candidateLower -match $rule.Pattern) {
    Write-Error "[BLOCKED] $($rule.Reason)"
    Write-Host "Safer alternative: $($rule.Safer)"
    exit 1
  }
}

exit 0
