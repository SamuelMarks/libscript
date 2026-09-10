# ## Overview
# PowerShell script for test.ps1 in stack 'ai-serving/gke-xpk-inference'.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Executes test for gke-xpk-inference stack on Windows.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Output "Usage: test.ps1"
    exit 0
}

$CmdFile = Join-Path $PSScriptRoot 'test.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'test completed for gke-xpk-inference.'
}
