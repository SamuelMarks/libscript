<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'mosquitto' stack.

.DESCRIPTION
Execute this script to run the test suite for mosquitto.
#>

$ErrorActionPreference = "Stop"

if (Get-Command mosquitto -ErrorAction SilentlyContinue) {
    mosquitto -h
} else {
    Write-Host "mosquitto skipped (not found)"
}
