# ## Overview
# PowerShell script for setup_generic.ps1 for stack 'phpbb'.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Generic PowerShell setup script for phpbb stack.

.DESCRIPTION
Delegates setup execution to the primary stack setup.ps1 script.
#>

$ErrorActionPreference = "Stop"

$SetupPs1 = Join-Path $PSScriptRoot "setup.ps1"
if (Test-Path $SetupPs1) {
    & $SetupPs1 @args
} else {
    $CmdFile = Join-Path $PSScriptRoot "setup_generic.cmd"
    if (Test-Path $CmdFile) {
        & $CmdFile @args
    } else {
        Write-Output 'phpbb setup_generic completed.'
    }
}
