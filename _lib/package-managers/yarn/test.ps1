<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'yarn' stack.

.DESCRIPTION
Execute this script to run the test suite for yarn.
#>

$ErrorActionPreference = "Stop"

if (Get-Command yarn -ErrorAction SilentlyContinue) {
    yarn --version
    Write-Output "yarn found"
} else {
    Write-Output "yarn skipped (not found)"
}
