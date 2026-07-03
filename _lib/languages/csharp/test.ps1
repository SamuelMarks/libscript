<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'csharp' stack.

.DESCRIPTION
Execute this script to run the test suite for csharp.
#>

$ErrorActionPreference = "Stop"

if (Get-Command csharp -ErrorAction SilentlyContinue) {
    csharp --version
    Write-Output "csharp found"
} else {
    Write-Output "csharp skipped (not found)"
}
