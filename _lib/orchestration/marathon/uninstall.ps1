# ## Overview
# PowerShell script for uninstall.sh for Marathon.
#
# ## Usage
# Execute via PowerShell: .\uninstall.ps1 [args...]

<#
.SYNOPSIS
Handles removal/uninstallation of Marathon on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'marathon uninstallation completed.'
}
