# ## Overview
# PowerShell script for uninstall.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles the removal and uninstallation process for the component 'memcached' stack.

.DESCRIPTION
Execute this script to remove memcached and its associated configurations from the system.
#>

$ErrorActionPreference = "Stop"

$GenericUninstall = Join-Path $PSScriptRoot "uninstall_generic.ps1"
if (Test-Path $GenericUninstall) {
    . $GenericUninstall
} else {
    Write-Error "uninstall_generic.ps1 not found."
}
