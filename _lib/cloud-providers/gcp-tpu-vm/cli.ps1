# ## Overview
# PowerShell wrapper delegating GCP Cloud TPU VM CLI operations to cli.cmd.
#
# ## Usage
# powershell.exe -File _lib\cloud-providers\gcp-tpu-vm\cli.ps1 <action> [args...]

<#
.SYNOPSIS
Provides the command-line interface logic for the component 'gcp-tpu-vm'.

.DESCRIPTION
Execute this script to trigger the CLI behavior for gcp-tpu-vm.
#>

$ErrorActionPreference = "Stop"

$PACKAGE_NAME = "gcp-tpu-vm"
$env:PACKAGE_NAME = $PACKAGE_NAME

$CliCmd = Join-Path $PSScriptRoot "cli.cmd"

if (Test-Path $CliCmd) {
    & $CliCmd @args
    exit $LASTEXITCODE
} else {
    Write-Error "Could not find cli.cmd in $PSScriptRoot"
    exit 1
}
