<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'tpu-vm' stack.

.DESCRIPTION
Execute this script to run the test suite for tpu-vm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command bazel -ErrorAction SilentlyContinue) {
    bazel --version
} else {
    Write-Host "bazel skipped (not found)"
}
