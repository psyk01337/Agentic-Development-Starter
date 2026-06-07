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

$markdownFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.md" -File | Where-Object { $_.FullName -notmatch "[\\/]\.git[\\/]" }
foreach ($file in $markdownFiles) {
  $relativeFile = [System.IO.Path]::GetRelativePath($RepoRoot, $file.FullName).Replace("\", "/")
  $lines = Get-Content -Path $file.FullName
  for ($index = 0; $index -lt $lines.Count; $index++) {
    if ($lines[$index] -match "\s+$") {
      Add-CheckError("Trailing whitespace in ${relativeFile}:$($index + 1)")
    }
  }

  $content = Get-Content -Path $file.FullName -Raw
  foreach ($match in [regex]::Matches($content, "\]\(([^)]+)\)")) {
    $target = $match.Groups[1].Value
    if ([string]::IsNullOrWhiteSpace($target) -or $target.StartsWith("http://") -or $target.StartsWith("https://") -or $target.StartsWith("mailto:") -or $target.StartsWith("#")) {
      continue
    }

    $cleanTarget = ($target -split "#", 2)[0].Replace("%20", " ")
    if ([string]::IsNullOrWhiteSpace($cleanTarget)) {
      continue
    }

    if ([System.IO.Path]::IsPathRooted($cleanTarget)) {
      $candidate = Join-Path $RepoRoot $cleanTarget.TrimStart("/", "\")
    } else {
      $candidate = Join-Path $file.DirectoryName $cleanTarget
    }

    if (-not (Test-Path $candidate)) {
      Add-CheckError("Broken local Markdown link in ${relativeFile}: $target")
    }
  }
}

if ($errors.Count -gt 0) {
  foreach ($message in $errors) {
    Write-Error $message
  }
  exit 1
}

Write-Host "Markdown quality checks passed."
exit 0