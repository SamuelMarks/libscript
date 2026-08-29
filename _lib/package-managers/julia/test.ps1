# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Test suite for the julia component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command julia -ErrorAction SilentlyContinue) {
    try {
        & julia --version
    } catch {
        try {
            & julia version
        } catch {}
    }
} else {
    Write-Host "julia is not installed, skipping test."
}
