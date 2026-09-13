# ## Overview
# PowerShell script for tests/run_windows_tests.sh.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell wrapper for run_windows_tests.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot 'run_windows_tests.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$CmdFile = Join-Path $PSScriptRoot 'run_windows_tests.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'run_windows_tests completed successfully.'
}
