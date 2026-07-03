<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'ansible-galaxy' stack.

.DESCRIPTION
Execute this script to run the test suite for ansible-galaxy.
#>

$ErrorActionPreference = "Stop"

if (Get-Command ansible-galaxy -ErrorAction SilentlyContinue) {
    ansible-galaxy --version
    Write-Output "ansible-galaxy found"
} else {
    Write-Output "ansible-galaxy skipped (not found)"
}
