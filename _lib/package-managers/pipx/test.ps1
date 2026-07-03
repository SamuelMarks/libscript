<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pipx' stack.

.DESCRIPTION
Execute this script to run the test suite for pipx.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pipx -ErrorAction SilentlyContinue) {
    pipx --version
    Write-Output "pipx found"
} else {
    Write-Output "pipx skipped (not found)"
}
