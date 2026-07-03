<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for java.
#>

$ErrorActionPreference = "Stop"

$JavaVersion = $env:JAVA_VERSION
if ([string]::IsNullOrEmpty($JavaVersion)) {
    $JavaVersion = "17"
}
if ($JavaVersion -eq "latest") {
    $JavaVersion = "21"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$JavaDir = Join-Path $LibscriptHome "java\$JavaVersion"
$env:JAVA_HOME = $JavaDir
$JavaBinPath = Join-Path $JavaDir "bin"
if (-not ($env:PATH -split ';' -contains $JavaBinPath)) {
    $env:PATH = "$JavaBinPath;" + $env:PATH
}