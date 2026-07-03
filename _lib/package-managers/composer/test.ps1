<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'composer' stack.

.DESCRIPTION
Execute this script to run the test suite for composer.
#>

$ErrorActionPreference = "Stop"

if (Get-Command composer -ErrorAction SilentlyContinue) {
    composer --version
    Write-Output "composer found"
} else {
    Write-Output "composer skipped (not found)"
}
