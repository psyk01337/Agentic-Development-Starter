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
if ([Console]::IsInputRedirected) {
  try {
    $stdin = [Console]::In.ReadToEnd()
  } catch {
    $stdin = ""
  }
}

# Flatten JSON punctuation to spaces so anchors such as (^|\s) still match a
# command that arrives inside a JSON string value.
$flattened = $stdin -replace '[{}\[\]",]', ' '

$candidate = ($ToolName + " " + $Action + " " + $Command + " " + $flattened).Trim()

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$rules = Get-PolicyRules -RepoRoot $repoRoot

foreach ($rule in $rules) {
  if ($candidate -match $rule.Pattern) {
    $decision = @{
      permissionDecision = "deny"
      permissionDecisionReason = "$($rule.Reason) $($rule.Safer)"
    } | ConvertTo-Json -Compress
    Write-Output $decision
    Write-Error "[BLOCKED] $($rule.Reason)"
    Write-Host "Safer alternative: $($rule.Safer)"
    # Exit 2 is an explicit deny for preToolUse, and denies even if stdout is ignored.
    exit 2
  }
}

# The engine owns stage and write-set policy. It is consulted only when a run
# exists, so ordinary editing never pays for the call and never fails on it.
$stateDir = Join-Path $repoRoot ".agentic\state"
$enginePath = Join-Path $repoRoot ".github\scripts\agentic_engine.py"

if ((Test-Path $stateDir -PathType Container) -and (Test-Path $enginePath -PathType Leaf)) {
  $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
  if (-not $pythonCmd) {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
  }

  if (-not $pythonCmd) {
    Write-Output '{"permissionDecision":"deny","permissionDecisionReason":"a run is active but no Python interpreter is available to gate it"}'
    Write-Error "[BLOCKED] a run is active but no Python interpreter is available to gate it"
    exit 2
  }

  $engineOutput = $stdin | & $pythonCmd.Source $enginePath check-tool 2>&1
  $engineExit = $LASTEXITCODE

  if ($engineExit -ne 0) {
    $engineText = ($engineOutput | Out-String).Trim()
    if ($engineText.StartsWith("{")) {
      Write-Output $engineText
    } else {
      Write-Error "[BLOCKED] engine gate failed: $engineText"
      Write-Output '{"permissionDecision":"deny","permissionDecisionReason":"engine gate failed for an active run"}'
    }
    exit 2
  }
}

exit 0
