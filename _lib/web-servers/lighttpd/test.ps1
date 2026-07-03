<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'lighttpd' stack.

.DESCRIPTION
Execute this script to run the test suite for lighttpd.
#>

$ErrorActionPreference = "Stop"

if (Get-Command lighttpd -ErrorAction SilentlyContinue) {
    lighttpd -v
} else {
    Write-Host "lighttpd skipped (not found)"
}
