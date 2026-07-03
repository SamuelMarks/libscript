<#
.SYNOPSIS
Provides the command-line interface logic for the component '_common' stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for _common.
#>

$ErrorActionPreference = "Stop"

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
