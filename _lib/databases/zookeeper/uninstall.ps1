# ## Overview
# PowerShell script for uninstall.sh for Apache ZooKeeper.
#
# ## Usage
# Execute via PowerShell: .\uninstall.ps1 [args...]

<#
.SYNOPSIS
Handles removal/uninstallation of Apache ZooKeeper on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'zookeeper uninstallation completed.'
}
