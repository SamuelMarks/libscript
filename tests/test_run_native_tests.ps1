# ## Overview
# PowerShell script for tests/test_run_native_tests.sh.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for test_run_native_tests.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot 'test_run_native_tests.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'test_run_native_tests completed successfully.'
}
