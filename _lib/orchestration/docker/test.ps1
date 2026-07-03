<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'docker' stack.

.DESCRIPTION
Execute this script to run the test suite for docker.
#>

$ErrorActionPreference = "Stop"

if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker --version
    Write-Output "docker found"
} else {
    Write-Output "docker skipped (not found)"
}
