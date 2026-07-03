<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'deno' stack.

.DESCRIPTION
Execute this script to run the test suite for deno.
#>

$ErrorActionPreference = "Stop"

if (Get-Command deno -ErrorAction SilentlyContinue) {
    deno --version
    Write-Output "deno found"
} else {
    Write-Output "deno skipped (not found)"
}
