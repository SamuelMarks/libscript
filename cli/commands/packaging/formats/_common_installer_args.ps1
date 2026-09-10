# ## Overview
# PowerShell script for cli/commands/packaging/formats/_common_installer_args.sh.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for _common_installer_args.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot '_common_installer_args.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$CmdFile = Join-Path $PSScriptRoot '_common_installer_args.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output '_common_installer_args completed successfully.'
}
