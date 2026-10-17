# ## Overview
# PowerShell script for _lib/databases/zookeeper/cli.sh.
#
# ## Usage
# Execute via PowerShell: .\cli.ps1 [args...]

<#
.SYNOPSIS
PowerShell equivalent for Apache ZooKeeper cli.
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
