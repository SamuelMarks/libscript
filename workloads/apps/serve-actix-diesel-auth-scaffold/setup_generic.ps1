# ## Overview
# PowerShell script for setup_generic.ps1 for stack 'serve-actix-diesel-auth-scaffold'.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Generic PowerShell setup script for serve-actix-diesel-auth-scaffold stack.

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
        Write-Output 'serve-actix-diesel-auth-scaffold setup_generic completed.'
    }
}
