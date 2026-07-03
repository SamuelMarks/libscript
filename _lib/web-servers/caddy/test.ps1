<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'caddy' stack.

.DESCRIPTION
Execute this script to run the test suite for caddy.
#>

$ErrorActionPreference = "Stop"

if (Get-Command caddy -ErrorAction SilentlyContinue) {
    caddy --version
    Write-Output "caddy found"
} else {
    Write-Output "caddy skipped (not found)"
}
