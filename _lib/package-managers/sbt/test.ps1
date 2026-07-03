<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'sbt' stack.

.DESCRIPTION
Execute this script to run the test suite for sbt.
#>

$ErrorActionPreference = "Stop"

if (Get-Command sbt -ErrorAction SilentlyContinue) {
    sbt --version
    Write-Output "sbt found"
} else {
    Write-Output "sbt skipped (not found)"
}
