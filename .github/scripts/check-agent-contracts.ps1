param(
  [string]$RepoRoot = ""
)

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
} else {
  $RepoRoot = Resolve-Path $RepoRoot
}

$errors = New-Object System.Collections.Generic.List[string]

function Add-CheckError([string]$Message) {
  $script:errors.Add($Message)
}

function Assert-FileExists([string]$RelativePath) {
  $fullPath = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $fullPath)) {
    Add-CheckError("Missing required file: $RelativePath")
  }
}

function Assert-FileContains([string]$RelativePath, [string]$Pattern, [string]$Description) {
  $fullPath = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $fullPath)) {
    Add-CheckError("Cannot verify $Description because file is missing: $RelativePath")
    return
  }

  $content = Get-Content -Path $fullPath -Raw
  if ($content -notmatch $Pattern) {
    Add-CheckError("Missing expected content for $Description in $RelativePath")
  }
}

$agentFiles = @(
  ".github/agents/analyst.agent.md",
  ".github/agents/tech-planner.agent.md",
  ".github/agents/architecture-reviewer.agent.md",
  ".github/agents/senior-software-engineer.agent.md",
  ".github/agents/code-reviewer.agent.md",
  ".github/agents/qa.agent.md",
  ".github/agents/process-improvement.agent.md",
  ".github/agents/tdd-vitest.agent.md",
  ".github/agents/orchestration-coordinator.agent.md"
)

foreach ($relativePath in $agentFiles) {
  Assert-FileExists -RelativePath $relativePath
  Assert-FileContains -RelativePath $relativePath -Pattern "## Handoff Memory Contract" -Description "handoff memory contract section"
  Assert-FileContains -RelativePath $relativePath -Pattern "## Escalation and Failure Modes" -Description "escalation and failure modes section"
}

Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "## Conditional Delegation Triggers" -Description "conditional delegation trigger table"
Assert-FileContains -RelativePath "docs/runbooks/agentic-dev.md" -Pattern "## 1b\) Redirect Mid-Chain When Signals Appear" -Description "mid-chain redirect runbook guidance"
Assert-FileContains -RelativePath "docs/runbooks/agentic-dev.md" -Pattern "### 4b\) Respect Escalation and Failure Mode Signals" -Description "escalation handling runbook guidance"

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Agent contract check passed."
exit 0
