# ## Overview
# Audits documentation coverage of component README.md files, schema keys, shell functions,
# and script header comments (.sh, .cmd, .ps1), and optionally updates the doc coverage shield in README.md.
#
# ## Usage
#   powershell.exe -File devtools\audit\doc_coverage.ps1 [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT]

<#
.SYNOPSIS
PowerShell documentation coverage auditor and README shield updater for LibScript.
#>

$ErrorActionPreference = "Stop"

# ## Show-Help
# Displays command-line usage instructions and available options.
function Show-Help {
    Write-Host "Usage: doc_coverage.ps1 [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT] [--help]"
    Write-Host "Audits documentation coverage and updates the % doc coverage shield in README.md."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --strict                       Fail with exit code 1 if coverage is below 100%."
    Write-Host "  --update-readme [README_PATH]  Update the Doc Coverage shield in README.md."
    Write-Host "  --repo-root REPO_ROOT          Override repository root directory."
    Write-Host "  --help, -h, /?, -?             Show this help message."
}

$updateReadme = $false
$readmeFile = ""
$repoRoot = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { "" }

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string]$args[$i]
    if ($arg -eq "--help" -or $arg -eq "-h" -or $arg -eq "/?" -or $arg -eq "-?") {
        Show-Help
        exit 0
    } elseif ($arg -eq "--strict") {
        # Strict mode is enabled by default
    } elseif ($arg -eq "--update-readme") {
        $updateReadme = $true
        if ($i + 1 -lt $args.Count -and -not ([string]$args[$i + 1]).StartsWith("--")) {
            $readmeFile = [string]$args[++$i]
        }
    } elseif ($arg -eq "--repo-root") {
        if ($i + 1 -lt $args.Count) {
            $repoRoot = [string]$args[++$i]
        }
    }
}

if (-not $repoRoot) {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
} else {
    $repoRoot = (Resolve-Path $repoRoot).Path
}

if (-not $readmeFile) {
    $readmeFile = Join-Path $repoRoot "README.md"
}

Write-Host "==> Auditing Component README.md Coverage..."
$totalComps = 0
$missingCompReadmes = 0
$libDir = Join-Path $repoRoot "_lib"
if (Test-Path -LiteralPath $libDir) {
    $catDirs = Get-ChildItem -LiteralPath $libDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_common" }
    foreach ($cat in $catDirs) {
        $compDirs = Get-ChildItem -LiteralPath $cat.FullName -Directory -ErrorAction SilentlyContinue
        foreach ($comp in $compDirs) {
            $totalComps++
            $compReadme = Join-Path $comp.FullName "README.md"
            if (-not (Test-Path -LiteralPath $compReadme -PathType Leaf)) {
                Write-Warning "Component $($comp.FullName) is missing README.md"
                $missingCompReadmes++
            }
        }
    }
}

Write-Host "==> Auditing Script Header Markdown Docstring Coverage (.sh, .cmd, .bat, .ps1)..."
$totalScripts = 0
$missingScriptHeaders = 0
$scriptFiles = @()

Push-Location $repoRoot
try {
    $trackedScripts = $null
    if (Test-Path -LiteralPath (Join-Path $repoRoot ".git")) {
        $trackedScripts = git ls-files "*.sh" "*.cmd" "*.bat" "*.ps1" 2>$null
    }
    if (-not $trackedScripts) {
        $trackedScripts = Get-ChildItem -Path $repoRoot -Include "*.sh", "*.cmd", "*.bat", "*.ps1" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $_.FullName.Substring($repoRoot.Length).TrimStart([char]92, [char]47)
        }
    }
    foreach ($relPath in $trackedScripts) {
        $norm = ([string]$relPath).Replace([char]92, [char]47)
        if ($norm -match '^(\.git|gen|cache|tmp|tests_tmp|node_modules|vagrant)/') {
            continue
        }
        $fullPath = Join-Path $repoRoot $relPath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }
        $scriptFiles += Get-Item -LiteralPath $fullPath
        $totalScripts++
        $headLines = (Get-Content -LiteralPath $fullPath -TotalCount 30 -ErrorAction SilentlyContinue) -join "`n"
        if ($headLines -notmatch '## Overview' -or $headLines -notmatch '## Usage') {
            Write-Warning "Script $norm is missing markdown header comments (## Overview / ## Usage)"
            $missingScriptHeaders++
        }
    }
} finally {
    Pop-Location
}

Write-Host "==> Auditing Schema Description Coverage..."
$missingSchema = 0
Get-ChildItem -Path $repoRoot -Filter "*.schema.json" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($c -match '"type":' -and $c -notmatch '"description":') {
        Write-Warning "Schema file $($_.FullName) might be missing descriptions."
        $missingSchema++
    }
}

Write-Host "==> Auditing PowerShell Function Docstring Coverage..."
$missingPs1Functions = 0
foreach ($sf in ($scriptFiles | Where-Object { $_.Extension -eq ".ps1" })) {
    $lines = [System.IO.File]::ReadAllLines($sf.FullName)
    $hasDoc = $false
    $inHereStr = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $ln = $lines[$i]
        if ($inHereStr) {
            if ($ln -match '^"@' -or $ln -match "^'@") { $inHereStr = $false }
            continue
        }
        if ($ln -match '@"\s*$' -or $ln -match "@'\s*$") { $inHereStr = $true; continue }
        if ($ln -match '^\s*#\s*##\s+') { $hasDoc = $true; continue }
        if ($ln -match '^\s*#') { continue }
        if ($ln -match '^\s*function\s+[A-Za-z0-9_-]+') {
            if (-not $hasDoc) {
                Write-Warning "Missing PowerShell function docstring in $($sf.FullName):$($i + 1)"
                $missingPs1Functions++
            }
            $hasDoc = $false
            continue
        }
        if ($ln -match '^\s*$') { continue }
        $hasDoc = $false
    }
}

$totalItems = $totalComps + $totalScripts
$missingItems = $missingCompReadmes + $missingScriptHeaders
$documentedItems = $totalItems - $missingItems
if ($totalItems -gt 0) {
    $coveragePct = [int][Math]::Floor(($documentedItems * 100.0) / $totalItems)
} else {
    $coveragePct = 100
}

Write-Host "==> Documentation Coverage: $coveragePct% ($documentedItems/$totalItems documented: $($totalComps - $missingCompReadmes)/$totalComps component READMEs, $($totalScripts - $missingScriptHeaders)/$totalScripts script headers)"

if ($updateReadme -and (Test-Path -LiteralPath $readmeFile -PathType Leaf)) {
    $badgeColor = "brightgreen"
    if ($coveragePct -lt 100) {
        $badgeColor = if ($coveragePct -ge 80) { "yellow" } else { "red" }
    }
    $shieldLine = "[![Doc Coverage](https://img.shields.io/badge/doc%20coverage-$($coveragePct)%25-$badgeColor.svg)](DOCS_ROADMAP.md)"
    $content = [System.IO.File]::ReadAllText($readmeFile, [System.Text.Encoding]::UTF8)

    if ($content -match '\[!\[Doc Coverage\]\(https://img\.shields\.io/badge/doc%20coverage-[^\)]*\)\]\([^\)]*\)') {
        $newContent = [regex]::Replace($content, '\[!\[Doc Coverage\]\(https://img\.shields\.io/badge/doc%20coverage-[^\)]*\)\]\([^\)]*\)', $shieldLine)
    } elseif ($content -match '(?m)^\[!\[CI Tests\]\([^\)]*\)\]\([^\)]*\)') {
        $newContent = [regex]::Replace($content, '(?m)^(\[!\[CI Tests\]\([^\)]*\)\]\([^\)]*\))', "`$1`n$shieldLine")
    } elseif ($content -match '(?m)^\[!\[License\]\([^\)]*\)\]\([^\)]*\)') {
        $newContent = [regex]::Replace($content, '(?m)^(\[!\[License\]\([^\)]*\)\]\([^\)]*\))', "`$1`n$shieldLine")
    } else {
        $newContent = "$shieldLine`n$content"
    }

    if ($newContent -ne $content) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($readmeFile, $newContent, $utf8NoBom)
    }
}

$totalErrors = $missingCompReadmes + $missingScriptHeaders + $missingSchema + $missingPs1Functions
if ($totalErrors -eq 0) {
    Write-Host "[PASS] 100% Documentation Coverage Audit Passed!"
    exit 0
} else {
    [Console]::Error.WriteLine("[ERROR] Found $missingCompReadmes missing component READMEs, $missingScriptHeaders scripts missing header docs, $missingSchema schema files with missing descriptions, and $missingPs1Functions PowerShell functions missing docstrings.")
    exit 1
}
