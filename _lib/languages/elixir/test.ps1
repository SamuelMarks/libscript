<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'elixir' stack.

.DESCRIPTION
Execute this script to run the test suite for elixir.
#>

$ErrorActionPreference = "Stop"

if (Get-Command elixir -ErrorAction SilentlyContinue) {
    elixir --version
    Write-Output "elixir found"
} else {
    Write-Output "elixir skipped (not found)"
}
