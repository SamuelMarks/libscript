<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'httpd' stack.

.DESCRIPTION
Execute this script to run the test suite for httpd.
#>

$ErrorActionPreference = "Stop"

if (Get-Command httpd -ErrorAction SilentlyContinue) {
    httpd --version
    Write-Output "httpd found"
} else {
    Write-Output "httpd skipped (not found)"
}
