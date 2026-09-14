# ## Overview
# Performs an audit and validation of all defined application stacks.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for audit_stacks.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Host "Usage: audit_stacks.ps1"
    Write-Host "Performs an audit and validation of all defined application stacks."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --help, -h, /?, -?  Show this help message."
    exit 0
}

$rootDir = if ($env:ROOT_DIR) { Resolve-Path $env:ROOT_DIR } else { Resolve-Path (Join-Path $PSScriptRoot '..\..') }
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$stacks = Get-ChildItem -Path (Join-Path $rootDir 'stacks') -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -ne 'stacks' }

foreach ($stack in $stacks) {
    $readmePath = Join-Path $stack.FullName 'README.md'
    
    if (-Not (Test-Path $readmePath)) {
        Write-Host "WARNING: Stack $($stack.Name) is missing a README.md"
        continue
    }

    $content = Get-Content $readmePath -Raw

    if ($content -notmatch '(?i)components' -and $content -notmatch '(?i)orchestrates' -and $content -notmatch '(?i)libscript\.json') {
        Write-Host "WARNING: Stack $($stack.Name) README may not explicitly list orchestrated _lib components or libscript.json usage."
        
        if ($content -notmatch '(?i)## Orchestrated Components') {
            $content += "`n## Orchestrated Components`nThis stack orchestrates the following LibScript components:`n- (Please document required components here)`n"
            [IO.File]::WriteAllText($readmePath, $content, $utf8NoBom)
        }
    }
}
Write-Host 'Stack audit complete.'
