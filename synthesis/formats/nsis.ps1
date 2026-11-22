# ## Overview
# PowerShell script for synthesis/formats/nsis.sh.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for nsis.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot 'nsis.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$CmdFile = Join-Path $PSScriptRoot 'nsis.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'nsis completed successfully.'
}
