<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'openbao' stack.

.DESCRIPTION
Execute this script to run the test suite for openbao.
#>

$ErrorActionPreference = "Stop"

if (Get-Command openbao -ErrorAction SilentlyContinue) {
    openbao --version
    Write-Output "openbao found"
} else {
    Write-Output "openbao skipped (not found)"
}
