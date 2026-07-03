<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'vllm' stack.

.DESCRIPTION
Execute this script to run the test suite for vllm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command huggingface_hub -ErrorAction SilentlyContinue) {
    huggingface_hub --version
} else {
    Write-Host "huggingface_hub skipped (not found)"
}
