param(
  [string]$RepoRoot = ""
)

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
} else {
  $RepoRoot = Resolve-Path $RepoRoot
}

# check-starter-manifest carries rules that only fire once the repository has already drifted:
# a stale count, an unlogged intake, a check nobody runs. On a clean repository they are
# invisible, so a regression in one of them would ship silently. That is the same "a guardrail
# nobody checks is a comment" problem, one level up.
#
# Each case copies the working tree, breaks exactly one thing, runs the check, and requires the
# expected message. A fresh copy per case means a crash here cannot leave anything mutated.

$checkScript = Join-Path $RepoRoot ".github/scripts/check-starter-manifest.ps1"
if (-not (Test-Path -Path $checkScript -PathType Leaf)) {
  Write-Error "Missing check script: .github/scripts/check-starter-manifest.ps1"
  exit 1
}

$excluded = @(".git", ".forlocal", ".agentic", "__pycache__")

function Copy-Tree([string]$Source, [string]$Destination) {
  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  Get-ChildItem -Path $Source -Force |
    Where-Object { $excluded -notcontains $_.Name } |
    ForEach-Object { Copy-Item -Path $_.FullName -Destination $Destination -Recurse -Force }
}

function Set-Text([string]$Path, [string]$Text) {
  [System.IO.File]::WriteAllText($Path, $Text)
}

function Invoke-BadgeMutation([string]$Tree) {
  $path = Join-Path $Tree "README.md"
  Set-Text $path ([System.IO.File]::ReadAllText($path).Replace("engine%20tests-", "engine%20tests-9"))
  return "engine-test badge"
}

function Invoke-AppMutation([string]$Tree) {
  $src = Join-Path $Tree "app/src"
  New-Item -ItemType Directory -Path $src -Force | Out-Null
  Set-Text (Join-Path $src "probe.js") "export const probe = 1;`n"
  return "placeholder verification command"
}

function Invoke-IntakeMutation([string]$Tree) {
  $inputs = Join-Path $Tree "docs/inputs"
  New-Item -ItemType Directory -Path $inputs -Force | Out-Null
  Set-Text (Join-Path $inputs "probe-intake.md") "# probe`n"
  return "never mentions"
}

function Invoke-PrdMutation([string]$Tree) {
  $inputs = Join-Path $Tree "docs/inputs"
  New-Item -ItemType Directory -Path $inputs -Force | Out-Null
  Set-Text (Join-Path $inputs "probe-intake.md") "# probe`n"
  $prdPath = Join-Path $Tree "docs/prd.md"
  $prdText = [System.IO.File]::ReadAllText($prdPath)
  Set-Text $prdPath ([regex]::Replace($prdText, "(?m)^\|\s*Source\s*\|.*$", "| Source | ``docs/inputs/probe-intake.md`` |", 1))
  return "names a concrete source"
}

function Invoke-UmbrellaMutation([string]$Tree) {
  Set-Text (Join-Path $Tree ".github/scripts/check-loose.ps1") "# loose`n"
  return "never runs them"
}

function Invoke-EmptyScriptMutation([string]$Tree) {
  Set-Text (Join-Path $Tree ".github/scripts/check-empty.ps1") ""
  return "effectively empty"
}

$cases = @(
  @{ Label = "baseline passes"; Mutate = $null; StarterOnly = $false },
  @{ Label = "a wrong README badge is caught"; Mutate = "badge"; StarterOnly = $true },
  @{ Label = "code behind a placeholder command is caught"; Mutate = "app"; StarterOnly = $false },
  @{ Label = "an unlogged intake is caught"; Mutate = "intake"; StarterOnly = $false },
  @{ Label = "a templated PRD with a concrete source is caught"; Mutate = "prd"; StarterOnly = $false },
  @{ Label = "a check the umbrella never runs is caught"; Mutate = "umbrella"; StarterOnly = $false },
  @{ Label = "an empty check script is caught"; Mutate = "empty"; StarterOnly = $false }
)

# The README count rule is gated on maintainerAssetScan, so it does not exist in a project. An
# adopting repository replaced the starter README and its numbers describe the starter, so there
# is nothing there to test. Reporting the case as skipped is honest; failing it, which is what
# happened until a real project ran this harness, blames the project for a rule it never had.
$starterMode = $false
$manifestPath = Join-Path $RepoRoot ".github/starter-modules.json"
if (Test-Path -Path $manifestPath -PathType Leaf) {
  try {
    $starterMode = [bool](Get-Content -Path $manifestPath -Raw | ConvertFrom-Json).maintainerAssetScan
  } catch {
    $starterMode = $false
  }
}

$failures = New-Object System.Collections.Generic.List[string]
$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("manifest-fixtures-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

try {
  for ($index = 0; $index -lt $cases.Count; $index++) {
    $case = $cases[$index]
    if ($case.StarterOnly -and -not $starterMode) {
      Write-Host "skip $($case.Label) (starter-only: this repository is in project mode)"
      continue
    }
    $tree = Join-Path $workRoot "case-$index"
    Copy-Tree -Source $RepoRoot -Destination $tree

    $marker = $null
    switch ($case.Mutate) {
      "badge" { $marker = Invoke-BadgeMutation $tree }
      "app" { $marker = Invoke-AppMutation $tree }
      "intake" { $marker = Invoke-IntakeMutation $tree }
      "prd" { $marker = Invoke-PrdMutation $tree }
      "umbrella" { $marker = Invoke-UmbrellaMutation $tree }
      "empty" { $marker = Invoke-EmptyScriptMutation $tree }
    }

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tree ".github/scripts/check-starter-manifest.ps1") -RepoRoot $tree 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String)

    if ($null -eq $case.Mutate) {
      $ok = ($exitCode -eq 0)
      $detail = if ($ok) { "" } else { "exit $exitCode`: $($text.Trim() -split "`n" | Select-Object -First 1)" }
    } else {
      $ok = ($exitCode -ne 0) -and $text.Contains($marker)
      $state = if ($text.Contains($marker)) { "present" } else { "absent" }
      $detail = if ($ok) { "" } else { "exit $exitCode, marker '$marker' $state" }
    }

    if ($ok) { Write-Host "ok   $($case.Label)" } else { Write-Host "FAIL $($case.Label)" }
    if (-not $ok) { $failures.Add("$($case.Label): $detail") }

    Remove-Item -Path $tree -Recurse -Force -ErrorAction SilentlyContinue
  }
} finally {
  Remove-Item -Path $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
  foreach ($failure in $failures) {
    Write-Error $failure
  }
  exit 1
}

Write-Host "Manifest fixture checks passed."
exit 0
