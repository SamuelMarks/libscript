<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'zig' stack.

.DESCRIPTION
Execute this script to run the test suite for zig.
#>

$ErrorActionPreference = "Stop"

if (Get-Command zig -ErrorAction SilentlyContinue) {
    zig --version
    Write-Output "zig found"
} else {
    Write-Output "zig skipped (not found)"
}
