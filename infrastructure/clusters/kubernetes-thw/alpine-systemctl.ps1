# ## Overview
# PowerShell script for infrastructure/clusters/kubernetes-thw/alpine-systemctl.sh.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for alpine-systemctl.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot 'alpine-systemctl.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$CmdFile = Join-Path $PSScriptRoot 'alpine-systemctl.cmd'
if (($env:OS -eq 'Windows_NT') -and (Test-Path $CmdFile)) {
    & cmd.exe /c "`"$CmdFile`"" @args
    exit $LASTEXITCODE
} else {
    Write-Host 'alpine-systemctl is not supported on Windows.'
    exit 86
}
