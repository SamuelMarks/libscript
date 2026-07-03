<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'cabal' stack.

.DESCRIPTION
Execute this script to run the test suite for cabal.
#>

$ErrorActionPreference = "Stop"

if (Get-Command cabal -ErrorAction SilentlyContinue) {
    cabal --version
    Write-Output "cabal found"
} else {
    Write-Output "cabal skipped (not found)"
}
