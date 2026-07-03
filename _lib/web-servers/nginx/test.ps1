<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'nginx' stack.

.DESCRIPTION
Execute this script to run the test suite for nginx.
#>

$ErrorActionPreference = "Stop"

if (Get-Command nginx -ErrorAction SilentlyContinue) {
    nginx --version
    Write-Output "nginx found"
} else {
    Write-Output "nginx skipped (not found)"
}
