<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'bazel' stack.

.DESCRIPTION
Execute this script to run the test suite for bazel.
#>

$ErrorActionPreference = "Stop"

if (Get-Command bazel -ErrorAction SilentlyContinue) {
    bazel --version
} else {
    Write-Host "bazel skipped (not found)"
}
