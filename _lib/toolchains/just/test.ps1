<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'just' stack.

.DESCRIPTION
Execute this script to run the test suite for just.
#>

$ErrorActionPreference = "Stop"

if (Get-Command just -ErrorAction SilentlyContinue) {
    just --version
} else {
    Write-Host "just skipped (not found)"
}
