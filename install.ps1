# ## Overview
# PowerShell script for install.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Global PowerShell installer for the libscript framework.

.DESCRIPTION
Execute this script to install libscript on the local system.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Output "Usage: install.ps1"
    Write-Output "Configure installation via environment variables."
    exit 0
}

$InstallCmd = Join-Path $PSScriptRoot "install.cmd"

if (Test-Path $InstallCmd) {
    & $InstallCmd @args
} else {
    Write-Error "Could not find install.cmd in $PSScriptRoot"
    exit 1
}
