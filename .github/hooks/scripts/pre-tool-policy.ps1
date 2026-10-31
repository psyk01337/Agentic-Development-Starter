param(
  [string]$ToolName = "",
  [string]$Action = "",
  [string]$Command = ""
)

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

function Get-DefaultRules {  return @(
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
  # Get-Content costs about 65ms more than this on every tool call, which is a
  # first-use cmdlet cost rather than file size: the rules file is 27 lines.
  foreach ($line in [IO.File]::ReadAllLines($rulesPath)) {
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

# Only command text is scanned. A payload for an edit tool also carries the file
# content being written, and matching against that blocks any file which merely
# mentions a blocked pattern - including this repository's own documentation.
# The accumulator must be an array: += on a bare string concatenates without a
# separator, which would weld a command onto the previous token and defeat every
# whitespace anchor.
$subjects = @()
foreach ($item in @($ToolName, $Action, $Command)) {
  if (-not [string]::IsNullOrWhiteSpace($item)) {
    $subjects += [string]$item
  }
}

if (-not [string]::IsNullOrWhiteSpace($stdin) -and $stdin.TrimStart().StartsWith("{")) {
  try {
    $payload = $stdin | ConvertFrom-Json
    # Several key names are accepted because the harness documents toolArgs as
    # provider-defined; a payload that carries none of them matches no rule, which
    # is recorded as a known gap rather than turned into a blanket denial.
    foreach ($key in @("command", "commandLine", "full_command_text", "cmd", "script")) {
      $commandText = [string]$payload.toolArgs.$key
      if (-not [string]::IsNullOrWhiteSpace($commandText)) {
        $subjects += $commandText
      }
    }
  } catch {
    # A payload that cannot be parsed yields no command text; matching nothing
    # is the correct outcome because no command is about to run.
  }
}

$candidate = ($subjects -join " ").Trim()

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$rules = Get-PolicyRules -RepoRoot $repoRoot

foreach ($rule in $rules) {
  if ($candidate -match $rule.Pattern) {
    $decision = @{
      permissionDecision = "deny"
      permissionDecisionReason = "$($rule.Reason) $($rule.Safer)"
    } | ConvertTo-Json -Compress
    Write-Output $decision
    [Console]::Error.WriteLine("[BLOCKED] $($rule.Reason)")
    Write-Host "Safer alternative: $($rule.Safer)"
    # Exit 2 is an explicit deny for preToolUse, and denies even if stdout is ignored.
    exit 2
  }
}

# The engine owns stage and write-set policy. It is consulted only when a run
# exists, so ordinary editing never pays for the call and never fails on it.
#
# A gate that cannot run must not brick the editor. The rule layer above is the
# safety control and has already run; the engine gate is a governance control,
# and denying every tool call because of a missing interpreter makes the whole
# policy get switched off - which is how this guardrail died once already.
$stateDir = if (-not [string]::IsNullOrWhiteSpace($env:AGENTIC_STATE_DIR)) { $env:AGENTIC_STATE_DIR } else { Join-Path $repoRoot ".agentic\state" }
$enginePath = Join-Path $repoRoot ".github\scripts\agentic_engine.py"

# The stage list mirrors ACTIVE_STAGES in the engine. check-hook-policy asserts
# that an active run is still gated, so a stage missing here cannot put the gate
# to sleep silently.
function Test-AnyActiveRun([string]$Dir) {
  $activeStages = @("approval", "implement", "verify", "repair", "review")
  foreach ($file in [IO.Directory]::GetFiles($Dir, "*.json")) {
    if ([IO.Path]::GetFileName($file).StartsWith(".tmp-")) { continue }
    try {
      $state = [IO.File]::ReadAllText($file) | ConvertFrom-Json
    } catch {
      # Unreadable state might be a live run mid-write. Ask the engine.
      return $true
    }
    if ($activeStages -contains [string]$state.stage) { return $true }
  }
  return $false
}

# Asking the engine costs two process spawns - the interpreter probe and the
# engine itself - and the answer is always "allow" once no run is in an active
# stage. Deciding that here costs a few milliseconds, so a session holding only
# finished runs pays nothing per tool call after the rules have been checked.
if ((Test-Path $stateDir -PathType Container) -and (Test-Path $enginePath -PathType Leaf) -and (Test-AnyActiveRun $stateDir)) {
  $pythonExe = Find-UsablePython

  if (-not $pythonExe) {
    [Console]::Error.WriteLine("[WARN] agentic engine gate skipped: no working Python interpreter. The write-set gate is OFF; the rule layer is unaffected.")
    exit 0
  }

  $engineOutput = $stdin | & $pythonExe $enginePath check-tool --state-dir $stateDir 2>&1
  $engineExit = $LASTEXITCODE

  if ($engineExit -eq 0) { exit 0 }

  $engineText = ($engineOutput | Out-String).Trim()
  if ($engineExit -eq 2 -and $engineText.StartsWith("{")) {
    Write-Output $engineText
    exit 2
  }

  [Console]::Error.WriteLine("[WARN] agentic engine gate failed (status $engineExit); allowing the call. $engineText")
  exit 0
}

exit 0
