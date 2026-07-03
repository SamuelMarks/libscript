<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'rbenv' stack.

.DESCRIPTION
Execute this script to run the test suite for rbenv.
#>

$ErrorActionPreference = "Stop"

if (Get-Command rbenv -ErrorAction SilentlyContinue) {
    rbenv --version
    Write-Output "rbenv found"
} else {
    Write-Output "rbenv skipped (not found)"
}
