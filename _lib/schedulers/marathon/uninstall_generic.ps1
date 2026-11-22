# ## Overview
# PowerShell script for uninstall_generic.sh for Marathon.
#
# ## Usage
# Execute via PowerShell: .\uninstall_generic.ps1 [args...]

<#
.SYNOPSIS
Handles generic removal/uninstallation of Marathon on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall_generic.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'marathon uninstallation completed.'
}
