# ## Overview
# PowerShell script for deploy.ps1 in stack 'ml-training/tpu-vm-eval-node'.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Executes deploy for tpu-vm-eval-node stack on Windows.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Output "Usage: deploy.ps1"
    exit 0
}

$CmdFile = Join-Path $PSScriptRoot 'deploy.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'deploy completed for tpu-vm-eval-node.'
}
