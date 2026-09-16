# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'memcached' stack.

.DESCRIPTION
Execute this script to install and configure memcached on the local system.
#>

$ErrorActionPreference = "Stop"

$MemcachedVersion = $env:MEMCACHED_VERSION
if ([string]::IsNullOrEmpty($MemcachedVersion)) {
    $MemcachedVersion = "latest"
}

$GenericSetup = Join-Path $PSScriptRoot "setup_generic.ps1"
if (Test-Path $GenericSetup) {
    . $GenericSetup
} else {
    Write-Error "setup_generic.ps1 not found."
}
