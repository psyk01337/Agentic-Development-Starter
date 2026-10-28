#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
  Validates the agentic driver and the overlay that would enable it.
#>
param(
  [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
$failed = $false

function Add-CheckError([string]$Message) {
  Write-Error $Message
  $script:failed = $true
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
}
$RepoRoot = (Resolve-Path $RepoRoot).Path

$driver = Join-Path $RepoRoot ".github/scripts/agentic_driver.py"
if (-not (Test-Path $driver)) {
  Add-CheckError("Missing .github/scripts/agentic_driver.py")
}
else {
  $output = & python $driver selftest 2>&1
  if ($LASTEXITCODE -ne 0) {
    Add-CheckError("Driver self-tests failed:")
    $output | ForEach-Object { Write-Host "    $_" }
  }
}

$manifestPath = Join-Path $RepoRoot ".github/starter-modules.json"
if (-not (Test-Path $manifestPath)) {
  Add-CheckError("Missing .github/starter-modules.json")
}
else {
  $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
  $overlay = $manifest.modules | Where-Object { $_.id -eq "overlay-autonomous-execution" }
  if (-not $overlay) {
    Add-CheckError("manifest is missing the overlay-autonomous-execution module")
  }
  else {
    if ($overlay.kind -ne "overlay") {
      Add-CheckError("overlay-autonomous-execution must have kind 'overlay'")
    }
    if ($overlay.defaultEnabled -ne $false) {
      Add-CheckError("overlay-autonomous-execution must be default-disabled")
    }
    if (@($overlay.files) -notcontains ".github/scripts/agentic_driver.py") {
      Add-CheckError("overlay-autonomous-execution must list the driver")
    }
  }
}

$driverText = Get-Content $driver -Raw
if ($driverText -notmatch [regex]::Escape("if kind is None:")) {
  Add-CheckError("Driver no longer denies unclassified tools")
}
if ($driverText -notmatch [regex]::Escape("return self._deny(")) {
  Add-CheckError("Driver no longer has an explicit denial path")
}

if ($failed) { exit 1 }
Write-Host "Agentic driver checks passed."