# ## Overview
# PowerShell script for uninstall.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell uninstallation wrapper for uWSGI.
#>
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "..\..\..\engine\common\uninstall_base.ps1") @Args
