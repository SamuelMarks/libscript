# ## Overview
# PowerShell script for cli.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Provides the command-line interface logic for the component 'swift' stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for swift.
#>

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "swift"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
