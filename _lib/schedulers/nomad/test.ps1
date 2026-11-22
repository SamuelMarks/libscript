# ## Overview
# PowerShell test script for HashiCorp Nomad.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

<#
.SYNOPSIS
Test suite for the HashiCorp Nomad component.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'test.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'nomad test completed.'
}
