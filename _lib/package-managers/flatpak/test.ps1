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
