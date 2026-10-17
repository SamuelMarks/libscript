# ## Overview
# PowerShell setup_generic script for Slurm Workload Manager.
#
# ## Usage
# Managed by libscript: .\setup_generic.ps1 [args...]

<#
.SYNOPSIS
Provides generic setup logic for Slurm Workload Manager on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot "setup_generic.cmd"
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'slurm setup_generic completed.'
}
