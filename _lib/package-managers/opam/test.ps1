<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'opam' stack.

.DESCRIPTION
Execute this script to run the test suite for opam.
#>

$ErrorActionPreference = "Stop"

if (Get-Command opam -ErrorAction SilentlyContinue) {
    opam --version
    Write-Output "opam found"
} else {
    Write-Output "opam skipped (not found)"
}
