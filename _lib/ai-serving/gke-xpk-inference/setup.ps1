# ## Overview
# PowerShell script for setup.ps1 in stack 'ai-serving/gke-xpk-inference'.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Executes setup for gke-xpk-inference stack on Windows.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Output "Usage: setup.ps1"
    exit 0
}

$CmdFile = Join-Path $PSScriptRoot 'setup.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'setup completed for gke-xpk-inference.'
}
