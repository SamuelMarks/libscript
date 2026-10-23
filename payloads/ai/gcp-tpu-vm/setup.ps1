# ## Overview
# PowerShell script for payloads/ai/gcp-tpu-vm/setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Executes setup for gcp-tpu-vm payload on Windows.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Output "Usage: setup.ps1 [--help]"
    exit 0
}

$CmdFile = Join-Path $PSScriptRoot 'setup.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'setup completed for gcp-tpu-vm.'
}
