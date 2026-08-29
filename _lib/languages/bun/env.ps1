# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for bun.
#>

$ErrorActionPreference = "Stop"

$BunVersion = $env:BUN_VERSION
if ([string]::IsNullOrEmpty($BunVersion)) {
    $BunVersion = "latest"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$BunPath = Join-Path $LibscriptHome "bun\$BunVersion\bin"
if (-not ($env:PATH -split ';' -contains $BunPath)) {
    $env:PATH = "$BunPath;" + $env:PATH
}