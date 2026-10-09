# ## Overview
# PowerShell script for cli.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell CLI wrapper for Open edX.
#>
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "..\..\..\_lib\_common\cli.ps1") @Args
