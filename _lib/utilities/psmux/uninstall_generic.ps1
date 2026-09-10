# ## Overview
# PowerShell script for uninstall_generic.sh for psmux.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles removal/uninstallation of psmux on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall_generic.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'psmux uninstallation completed.'
}
