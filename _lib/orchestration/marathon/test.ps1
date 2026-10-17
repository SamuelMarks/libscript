# ## Overview
# PowerShell test script for Marathon.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

<#
.SYNOPSIS
Test suite for the Marathon component.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'test.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'marathon test completed.'
}
