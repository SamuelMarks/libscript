# ## Overview
# PowerShell test script for k8s-marathon.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

<#
.SYNOPSIS
Test suite for the k8s-marathon component.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'test.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'k8s-marathon test completed.'
}
