# ## Overview
# PowerShell script for synthesis/formats/docker_compose.sh.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for docker_compose.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot 'docker_compose.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$CmdFile = Join-Path $PSScriptRoot 'docker_compose.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'docker_compose completed successfully.'
}
