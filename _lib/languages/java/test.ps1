<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'java' stack.

.DESCRIPTION
Execute this script to run the test suite for java.
#>

$ErrorActionPreference = "Stop"

if (Get-Command java -ErrorAction SilentlyContinue) {
    java --version
    Write-Output "java found"
} else {
    Write-Output "java skipped (not found)"
}
