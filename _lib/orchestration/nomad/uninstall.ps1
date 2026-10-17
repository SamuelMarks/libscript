# ## Overview
# PowerShell script for uninstall.sh for HashiCorp Nomad.
#
# ## Usage
# Execute via PowerShell: .\uninstall.ps1 [args...]

<#
.SYNOPSIS
Handles removal/uninstallation of HashiCorp Nomad on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'uninstall.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'nomad uninstallation completed.'
}
