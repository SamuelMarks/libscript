# ## Overview
# PowerShell setup_generic script for kubernetes.
#
# ## Usage
# Managed by libscript.

<#
.SYNOPSIS
Provides generic setup logic for kubernetes on Windows.
#>

$ErrorActionPreference = "Stop"

$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

$CmdFile = Join-Path $PSScriptRoot "setup_generic.cmd"
if (Test-Path $CmdFile) {
    & $CmdFile @args
} else {
    Write-Output 'kubernetes setup_generic completed.'
}
