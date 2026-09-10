# ## Overview
# PowerShell script for uninstall.sh for kubernetes.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles removal/uninstallation of kubernetes on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'kubernetes uninstallation completed.'
}
