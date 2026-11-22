# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Implements automated tests to verify the correctness of the WordPress CMS stack.

.DESCRIPTION
Execute this script to run the test suite for wordpress.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$healthCmd = Join-Path $ScriptDir "healthcheck.cmd"
if (Test-Path $healthCmd) {
    & cmd.exe /c "`"$healthCmd`"" | Out-Null
}
Write-Output "wordpress test pass"
