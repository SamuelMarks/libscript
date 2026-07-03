<#
.SYNOPSIS
Provides the command-line interface logic for the Actix+Diesel authentication scaffold stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for serve-actix-diesel-auth-scaffold.
#>

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "serve-actix-diesel-auth-scaffold"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
