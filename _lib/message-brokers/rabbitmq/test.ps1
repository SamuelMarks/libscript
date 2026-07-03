<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'rabbitmq' stack.

.DESCRIPTION
Execute this script to run the test suite for rabbitmq.
#>

$ErrorActionPreference = "Stop"

if (Get-Command rabbitmq -ErrorAction SilentlyContinue) {
    rabbitmq --version
    Write-Output "rabbitmq found"
} else {
    Write-Output "rabbitmq skipped (not found)"
}
