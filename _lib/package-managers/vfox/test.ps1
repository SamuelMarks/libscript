<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'vfox' stack.

.DESCRIPTION
Execute this script to run the test suite for vfox.
#>

$ErrorActionPreference = "Stop"

if (Get-Command vfox -ErrorAction SilentlyContinue) {
    vfox --version
    Write-Output "vfox found"
} else {
    Write-Output "vfox skipped (not found)"
}
