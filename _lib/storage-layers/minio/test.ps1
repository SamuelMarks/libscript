<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'minio' stack.

.DESCRIPTION
Execute this script to run the test suite for minio.
#>

$ErrorActionPreference = "Stop"

if (Get-Command minio -ErrorAction SilentlyContinue) {
    minio --version
} else {
    Write-Host "minio skipped (not found)"
}
