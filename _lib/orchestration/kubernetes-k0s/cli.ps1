<#
.SYNOPSIS
Provides the command-line interface logic for the component 'kubernetes-k0s' stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for kubernetes-k0s.
#>

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "kubernetes-k0s"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
