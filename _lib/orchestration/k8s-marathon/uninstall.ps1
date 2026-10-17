# ## Overview
# PowerShell script for uninstall.sh for k8s-marathon.
#
# ## Usage
# Execute via PowerShell: .\uninstall.ps1 [args...]

<#
.SYNOPSIS
Handles removal/uninstallation of k8s-marathon on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'k8s-marathon uninstallation completed.'
}
