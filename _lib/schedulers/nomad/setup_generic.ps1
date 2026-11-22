# ## Overview
# PowerShell setup_generic script for HashiCorp Nomad.
#
# ## Usage
# Managed by libscript: .\setup_generic.ps1 [args...]

<#
.SYNOPSIS
Provides generic setup logic for HashiCorp Nomad on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot "setup_generic.cmd"
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'nomad setup_generic completed.'
}
