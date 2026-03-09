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

$requiredFiles = @(
  ".github/agents/orchestration-coordinator.agent.md",
  ".github/skills/approval-gated-handoffs/SKILL.md",
  ".github/schema/approval-gated-handoff-envelope.schema.json",
  ".github/examples/approval-gated-handoffs/approved-tech-planner-to-senior-software-engineer.json",
  ".github/examples/approval-gated-handoffs/pending-architecture-reviewer-to-senior-software-engineer.json",
  ".github/examples/approval-gated-handoffs/rejected-qa-to-senior-software-engineer.json",
  ".github/examples/approval-gated-handoffs/stale-analyst-to-tech-planner.json",
  ".github/scripts/check-approval-gated-orchestration.ps1",
  ".github/scripts/check-approval-gated-orchestration.sh",
  "docs/runbooks/approval-gated-handoffs.md",
  "docs/adr/0001-approval-gated-orchestration-overlay.md"
)

foreach ($relativePath in $requiredFiles) {
  Assert-FileExists -RelativePath $relativePath
}

$manifestPath = Join-Path $RepoRoot ".github/starter-modules.json"
if (-not (Test-Path $manifestPath)) {
  Add-CheckError("Missing required file: .github/starter-modules.json")
} else {
  $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
  $overlay = $manifest.modules | Where-Object { $_.id -eq "overlay-approval-gated-orchestration" }
  if (-not $overlay) {
    Add-CheckError("starter-modules.json is missing overlay-approval-gated-orchestration")
  } else {
    foreach ($relativePath in $requiredFiles[0..9]) {
      if ($overlay.files -notcontains $relativePath) {
        Add-CheckError("overlay-approval-gated-orchestration is missing manifest file entry: $relativePath")
      }
    }
  }
}

Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "Inputs for next agent" -Description "core handoff contract extension"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "Decision status" -Description "decision status field"
Assert-FileContains -RelativePath ".github/AGENTS.md" -Pattern "overlay-only" -Description "overlay-only orchestration wording"
Assert-FileContains -RelativePath "docs/runbooks/approval-gated-handoffs.md" -Pattern "approval-gated-handoff-envelope\.schema\.json" -Description "schema reference"
Assert-FileContains -RelativePath "docs/runbooks/approval-gated-handoffs.md" -Pattern "jsonschema|ajv-cli" -Description "schema validation note"
Assert-FileContains -RelativePath "docs/runbooks/hooks.md" -Pattern "postToolUse" -Description "audit seam reuse guidance"
Assert-FileContains -RelativePath "docs/adr/0001-approval-gated-orchestration-overlay.md" -Pattern "default-disabled orchestration overlay" -Description "ADR decision wording"

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Approval-gated orchestration overlay check passed."
exit 0