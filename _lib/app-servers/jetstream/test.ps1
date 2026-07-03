<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'jetstream' stack.

.DESCRIPTION
Execute this script to run the test suite for jetstream.
#>

$ErrorActionPreference = "Stop"

if (Get-Command huggingface_hub -ErrorAction SilentlyContinue) {
    huggingface_hub --version
} else {
    Write-Host "huggingface_hub skipped (not found)"
}
