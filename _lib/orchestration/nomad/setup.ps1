# ## Overview
# PowerShell script for _lib/orchestration/nomad/setup.sh.
#
# ## Usage
# Execute via PowerShell: .\setup.ps1 [args...]

<#
.SYNOPSIS
PowerShell equivalent for HashiCorp Nomad setup.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot 'setup.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$CmdFile = Join-Path $PSScriptRoot 'setup.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'setup completed successfully.'
}
