<#
.SYNOPSIS
Provides the command-line interface logic for the component 'pyenv' stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for pyenv.
#>

$ErrorActionPreference = "Stop"

if (-not $env:PACKAGE_NAME) { $env:PACKAGE_NAME = (Get-Item $PSScriptRoot).Name }
$PACKAGE_NAME = $env:PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
