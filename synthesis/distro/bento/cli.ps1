# ## Overview
# PowerShell script for cli.ps1 for Bento Builder stack.
#
# ## Usage
# Execute via PowerShell.

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "bento-builder"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
