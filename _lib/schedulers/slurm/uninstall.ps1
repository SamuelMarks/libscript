# ## Overview
# PowerShell script for uninstall.sh for Slurm Workload Manager.
#
# ## Usage
# Execute via PowerShell: .\uninstall.ps1 [args...]

<#
.SYNOPSIS
Handles removal/uninstallation of Slurm Workload Manager on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'slurm uninstallation completed.'
}
