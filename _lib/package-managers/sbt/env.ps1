<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for sbt.
#>

$ErrorActionPreference = "Stop"

$SbtVersion = $env:SBT_VERSION
if ([string]::IsNullOrEmpty($SbtVersion)) {
    $SbtVersion = "latest"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$SbtPath = Join-Path $LibscriptHome "sbt\$SbtVersion\bin"
if (-not ($env:PATH -split ';' -contains $SbtPath)) {
    $env:PATH = "$SbtPath;" + $env:PATH
}