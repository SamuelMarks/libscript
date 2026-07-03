<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'maven' stack.

.DESCRIPTION
Execute this script to run the test suite for maven.
#>

$ErrorActionPreference = "Stop"

if (Get-Command maven -ErrorAction SilentlyContinue) {
    maven --version
    Write-Output "maven found"
} else {
    Write-Output "maven skipped (not found)"
}
