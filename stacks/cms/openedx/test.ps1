# ## Overview
# End-to-end integration test runner for Open edX on Windows PowerShell.
#
# ## Usage
# Execute this script to perform integration testing on Windows PowerShell.

<#
.SYNOPSIS
    End-to-end integration test runner for Open edX on Windows PowerShell.
#>
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "test_harness.ps1") @Args
exit $LASTEXITCODE
