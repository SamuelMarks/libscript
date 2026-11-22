# ## Overview
# PowerShell setup_generic script for Apache Mesos.
#
# ## Usage
# Managed by libscript: .\setup_generic.ps1 [args...]

<#
.SYNOPSIS
Provides generic setup logic for Apache Mesos on Windows.
#>

$ErrorActionPreference = "Stop"

$CmdFile = Join-Path $PSScriptRoot "setup_generic.cmd"
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'mesos setup_generic completed.'
}
