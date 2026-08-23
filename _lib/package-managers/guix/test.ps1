<#
.SYNOPSIS
Test suite for the guix component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command guix -ErrorAction SilentlyContinue) {
    & guix --version
} else {
    Write-Host "guix is not installed, skipping test."
}
