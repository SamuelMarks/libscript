# ## Overview
# PowerShell script for cli.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Provides the command-line interface logic for the Odoo ERP system stack.

.DESCRIPTION
Execute this script to trigger the CLI behavior for odoo.
#>

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "odoo"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
