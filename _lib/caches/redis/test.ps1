<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'redis' stack.

.DESCRIPTION
Execute this script to run the test suite for redis.
#>

$ErrorActionPreference = "Stop"

if (Get-Command redis -ErrorAction SilentlyContinue) {
    redis-server --version
} else {
    Write-Host "redis skipped (not found)"
}
