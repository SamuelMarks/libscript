# ## Overview
# PowerShell script for _lib/orchestration/mesos/cli.sh.
#
# ## Usage
# Execute via PowerShell: .\cli.ps1 [args...]

<#
.SYNOPSIS
PowerShell equivalent for Apache Mesos cli.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot 'cli.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$CmdFile = Join-Path $PSScriptRoot 'cli.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'cli completed successfully.'
}
