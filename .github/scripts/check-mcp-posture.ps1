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

$mcpPath = Join-Path $RepoRoot ".vscode\mcp.json"
if (-not (Test-Path $mcpPath)) {
  Add-CheckError("Missing MCP template: .vscode/mcp.json")
} else {
  $content = Get-Content -Path $mcpPath -Raw
  try {
    [void]($content | ConvertFrom-Json)
  } catch {
    Add-CheckError("MCP template is not valid JSON: .vscode/mcp.json")
  }

  if ($content -match '"enabled"\s*:\s*true') {
    Add-CheckError("MCP template must keep all servers and apps disabled by default.")
  }

  if ($content -match '(?i)(ghp_[a-z0-9]{20,}|sk-[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----)') {
    Add-CheckError("MCP template appears to contain a secret-like value.")
  }
}

$mcpRunbook = Join-Path $RepoRoot "docs\runbooks\mcp-servers.md"
foreach ($expected in @("MCP Approval Checklist", "Browser Automation MCP", "GitHub MCP", "Database MCP", "File-System MCP", "disabled by default")) {
  if (-not (Test-Path $mcpRunbook) -or (Get-Content -Path $mcpRunbook -Raw) -notlike "*$expected*") {
    Add-CheckError("MCP runbook is missing required guidance: $expected")
  }
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "MCP posture checks passed."
exit 0