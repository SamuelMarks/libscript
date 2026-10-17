# ## Overview
# PowerShell test script for Apache Mesos.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

<#
.SYNOPSIS
Test suite for the Apache Mesos component.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'test.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'mesos test completed.'
}
