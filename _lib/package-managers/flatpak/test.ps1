# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Test suite for the flatpak component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command flatpak -ErrorAction SilentlyContinue) {
    & flatpak --version
} else {
    Write-Host "flatpak is not installed, skipping test."
}
