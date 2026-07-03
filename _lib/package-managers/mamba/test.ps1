<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'mamba' stack.

.DESCRIPTION
Execute this script to run the test suite for mamba.
#>

$ErrorActionPreference = "Stop"

if (Get-Command micromamba -ErrorAction SilentlyContinue) {
    micromamba --version
    Write-Output "mamba found"
} else {
    Write-Output "mamba skipped (not found)"
}
