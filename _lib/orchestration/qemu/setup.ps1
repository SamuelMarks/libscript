# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates setup and installation for QEMU on Windows.
#>

$ErrorActionPreference = "Stop"

$SetupGeneric = Join-Path $PSScriptRoot "setup_generic.ps1"
if (Test-Path $SetupGeneric) {
    & $SetupGeneric @args
}
