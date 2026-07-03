<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'gradle' stack.

.DESCRIPTION
Execute this script to run the test suite for gradle.
#>

$ErrorActionPreference = "Stop"

if (Get-Command gradle -ErrorAction SilentlyContinue) {
    gradle --version
    Write-Output "gradle found"
} else {
    Write-Output "gradle skipped (not found)"
}
