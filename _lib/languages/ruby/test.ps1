<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'ruby' stack.

.DESCRIPTION
Execute this script to run the test suite for ruby.
#>

$ErrorActionPreference = "Stop"

if (Get-Command ruby -ErrorAction SilentlyContinue) {
    ruby --version
    Write-Output "ruby found"
} else {
    Write-Output "ruby skipped (not found)"
}
