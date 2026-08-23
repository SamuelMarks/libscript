<#
.SYNOPSIS
Test suite for the google-cloud-sdk component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command gcloud -ErrorAction SilentlyContinue) {
    & gcloud --version
} else {
    Write-Host "gcloud is not installed, skipping test."
}
