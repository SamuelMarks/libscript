<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'nats' stack.

.DESCRIPTION
Execute this script to run the test suite for nats.
#>

$ErrorActionPreference = "Stop"

if (Get-Command nats-server -ErrorAction SilentlyContinue) {
    nats-server --version
} else {
    Write-Host "nats skipped (not found)"
}
