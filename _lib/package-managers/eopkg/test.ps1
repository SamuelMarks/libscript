# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Test suite for the eopkg component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command eopkg -ErrorAction SilentlyContinue) {
    & eopkg --version
} else {
    Write-Host "eopkg is not installed, skipping test."
}
