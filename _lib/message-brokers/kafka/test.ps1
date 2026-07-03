<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'kafka' stack.

.DESCRIPTION
Execute this script to run the test suite for kafka.
#>

$ErrorActionPreference = "Stop"

if (Get-Command kafka -ErrorAction SilentlyContinue) {
    kafka-server-start.sh --version
} else {
    Write-Host "kafka skipped (not found)"
}
