# ## Overview
# PowerShell script for uninstall.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell uninstallation script for Open edX.
#>
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:ACTION = "uninstall"
& (Join-Path $ScriptDir "setup_generic.ps1")
