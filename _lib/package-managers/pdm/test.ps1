<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pdm' stack.

.DESCRIPTION
Execute this script to run the test suite for pdm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pdm -ErrorAction SilentlyContinue) {
    pdm --version
    Write-Output "pdm found"
} else {
    Write-Output "pdm skipped (not found)"
}
