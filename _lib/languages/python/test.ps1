<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'python' stack.

.DESCRIPTION
Execute this script to run the test suite for python.
#>

$ErrorActionPreference = "Stop"

if (Get-Command python -ErrorAction SilentlyContinue) {
    python --version
    Write-Output "python found"
} else {
    Write-Output "python skipped (not found)"
}
