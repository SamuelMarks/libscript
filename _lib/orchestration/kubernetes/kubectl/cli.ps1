<#
.SYNOPSIS
Provides the command-line interface logic for the component 'kubectl' stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for kubectl.
#>

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "kubectl"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
