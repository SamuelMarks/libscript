# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for deno.
#>

$ErrorActionPreference = "Stop"

$DenoVersion = $env:DENO_VERSION
if ([string]::IsNullOrEmpty($DenoVersion)) {
    $DenoVersion = "latest"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$DenoPath = Join-Path $LibscriptHome "deno\$DenoVersion\bin"
if (-not ($env:PATH -split ';' -contains $DenoPath)) {
    $env:PATH = "$DenoPath;" + $env:PATH
}