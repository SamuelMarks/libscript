# ## Overview
# PowerShell script for uninstall_generic.sh for gcsfuse.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles removal/uninstallation of gcsfuse on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall_generic.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'gcsfuse uninstallation completed.'
}
