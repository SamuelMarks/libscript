<#
.SYNOPSIS
Provides the command-line interface logic for the component 'rust' stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for rust.
#>

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "rust"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
