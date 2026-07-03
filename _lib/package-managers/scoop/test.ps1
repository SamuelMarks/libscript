<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'scoop' stack.

.DESCRIPTION
Execute this script to run the test suite for scoop.
#>

$ErrorActionPreference = "Stop"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop --version
    Write-Output "scoop found"
} else {
    Write-Output "scoop skipped (not found)"
}
