# ## Overview
# PowerShell script for cli.ps1 for VirtualBox.
#
# ## Usage
# Execute via PowerShell.

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "virtualbox"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
