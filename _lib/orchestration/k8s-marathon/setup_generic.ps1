# ## Overview
# PowerShell setup_generic script for k8s-marathon.
#
# ## Usage
# Managed by libscript: .\setup_generic.ps1 [args...]

<#
.SYNOPSIS
Provides generic setup logic for k8s-marathon on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot "setup_generic.cmd"
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'k8s-marathon setup_generic completed.'
}
