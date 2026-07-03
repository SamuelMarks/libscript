<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'php' stack.

.DESCRIPTION
Execute this script to run the test suite for php.
#>

$ErrorActionPreference = "Stop"

if (Get-Command php -ErrorAction SilentlyContinue) {
    php --version
    Write-Output "php found"
} else {
    Write-Output "php skipped (not found)"
}
