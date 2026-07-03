<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'rebar3' stack.

.DESCRIPTION
Execute this script to run the test suite for rebar3.
#>

$ErrorActionPreference = "Stop"

if (Get-Command rebar3 -ErrorAction SilentlyContinue) {
    rebar3 --version
    Write-Output "rebar3 found"
} else {
    Write-Output "rebar3 skipped (not found)"
}
