# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Test suite for the go-pm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command go -ErrorAction SilentlyContinue) {
    & go --version
} else {
    Write-Host "go is not installed, skipping test."
}
