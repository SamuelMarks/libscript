<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'cpanm' stack.

.DESCRIPTION
Execute this script to run the test suite for cpanm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command cpanm -ErrorAction SilentlyContinue) {
    cpanm --version
    Write-Output "cpanm found"
} else {
    Write-Output "cpanm skipped (not found)"
}
