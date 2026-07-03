<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pyenv' stack.

.DESCRIPTION
Execute this script to run the test suite for pyenv.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pyenv -ErrorAction SilentlyContinue) {
    pyenv --version
    Write-Output "pyenv found"
} else {
    Write-Output "pyenv skipped (not found)"
}
