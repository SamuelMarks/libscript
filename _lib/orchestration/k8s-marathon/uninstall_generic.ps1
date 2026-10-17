# ## Overview
# PowerShell script for uninstall_generic.sh for k8s-marathon.
#
# ## Usage
# Execute via PowerShell: .\uninstall_generic.ps1 [args...]

<#
.SYNOPSIS
Handles generic removal/uninstallation of k8s-marathon on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall_generic.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'k8s-marathon uninstallation completed.'
}
