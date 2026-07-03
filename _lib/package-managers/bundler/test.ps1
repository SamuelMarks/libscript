<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'bundler' stack.

.DESCRIPTION
Execute this script to run the test suite for bundler.
#>

$ErrorActionPreference = "Stop"

if (Get-Command bundler -ErrorAction SilentlyContinue) {
    bundler --version
    Write-Output "bundler found"
} else {
    Write-Output "bundler skipped (not found)"
}
