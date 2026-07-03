<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'gitlab' stack.

.DESCRIPTION
Execute this script to run the test suite for gitlab.
#>

$ErrorActionPreference = "Stop"

if (Get-Command gitlab -ErrorAction SilentlyContinue) {
    gitlab-ctl status
} else {
    Write-Host "gitlab skipped (not found)"
}
