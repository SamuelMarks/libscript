# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Test suite for the luarocks component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command luarocks -ErrorAction SilentlyContinue) {
    try {
        & luarocks --version
    } catch {
        try {
            & luarocks version
        } catch {}
    }
} else {
    Write-Host "luarocks is not installed, skipping test."
}
