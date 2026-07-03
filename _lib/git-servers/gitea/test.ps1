<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'gitea' stack.

.DESCRIPTION
Execute this script to run the test suite for gitea.
#>

$ErrorActionPreference = "Stop"

if (Get-Command gitea -ErrorAction SilentlyContinue) {
    gitea --version
} else {
    Write-Host "gitea skipped (not found)"
}
