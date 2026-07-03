<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for nodejs.
#>

$ErrorActionPreference = "Stop"
# Environment variables for PowerShell

$NodeVersion = $env:NODEJS_VERSION
if ([string]::IsNullOrEmpty($NodeVersion)) {
    $NodeVersion = "lts"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$NodePath = Join-Path $LibscriptHome "nodejs\$NodeVersion"
if (-not ($env:PATH -split ';' -contains $NodePath)) {
    $env:PATH = "$NodePath;" + $env:PATH
}
