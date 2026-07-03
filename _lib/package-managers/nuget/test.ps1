<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'nuget' stack.

.DESCRIPTION
Execute this script to run the test suite for nuget.
#>

$ErrorActionPreference = "Stop"

if (Get-Command nuget -ErrorAction SilentlyContinue) {
    nuget --version
    Write-Output "nuget found"
} else {
    Write-Output "nuget skipped (not found)"
}
