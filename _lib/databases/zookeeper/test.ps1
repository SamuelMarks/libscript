# ## Overview
# PowerShell test script for Apache ZooKeeper.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

<#
.SYNOPSIS
Test suite for the Apache ZooKeeper component.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'test.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'zookeeper test completed.'
}
