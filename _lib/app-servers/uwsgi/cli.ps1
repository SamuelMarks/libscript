# ## Overview
# PowerShell script for cli.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell CLI wrapper for uWSGI.
#>
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "..\..\_common\cli.ps1") @Args
