# ## Overview
# Injects specific markers or tags into documentation files.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for inject_markers.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Host "Usage: inject_markers.ps1"
    Write-Host "Injects specific markers or tags into documentation files."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --help, -h, /?, -?  Show this help message."
    exit 0
}

$rootDir = if ($env:ROOT_DIR) { Resolve-Path $env:ROOT_DIR } else { Resolve-Path (Join-Path $PSScriptRoot '..\..') }
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$libComps = Get-ChildItem -Path (Join-Path $rootDir '_lib') -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -ne '_lib' }
$stackComps = Get-ChildItem -Path (Join-Path $rootDir 'stacks') -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -ne 'stacks' }
$components = @($libComps) + @($stackComps)

foreach ($comp in $components) {
    $readmePath = Join-Path $comp.FullName 'README.md'
    if (-Not (Test-Path $readmePath)) { continue }

    $content = Get-Content $readmePath -Raw
    $modified = $false

    if ($content -notmatch '<!-- BEGIN_VARS -->') {
        $varsBlock = "## Configuration Options`n`nThe following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.`n`n<!-- BEGIN_VARS -->`n<!-- END_VARS -->`n`n"
        if ($content -match '(?i)## (Configuration Options|Variables|Environment Variables)') {
            $content = $content -replace '(?is)## (Configuration Options|Variables|Environment Variables).*?(?=^## |\Z)', $varsBlock
        } elseif ($content -match '(?i)## Platform Support') {
            $content = $content -replace '(?is)(## Platform Support)', ($varsBlock + '$1')
        } else {
            $content += "`n" + $varsBlock
        }
        $modified = $true
    }

    if ($content -notmatch '<!-- BEGIN_PLATFORMS -->') {
        $platBlock = "## Platform Support`n`n<!-- BEGIN_PLATFORMS -->`n<!-- END_PLATFORMS -->`n`n"
        if ($content -match '(?i)## Platform Support') {
            $content = $content -replace '(?is)## Platform Support.*?(?=^## |\Z)', $platBlock
        } elseif ($content -match '(?i)## Orchestrated Components') {
            $content = $content -replace '(?is)(## Orchestrated Components)', ($platBlock + '$1')
        } else {
            $content += "`n" + $platBlock
        }
        $modified = $true
    }

    if ($modified) {
        [IO.File]::WriteAllText($readmePath, $content, $utf8NoBom)
    }
}
Write-Host 'Markers injected.'
