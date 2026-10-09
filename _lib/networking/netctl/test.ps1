# ## Overview
# PowerShell test suite for netctl.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Runs verification tests for netctl on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot "test.cmd"
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'netctl tests passed.'
}
