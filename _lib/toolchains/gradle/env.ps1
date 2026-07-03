<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for gradle.
#>

$ErrorActionPreference = "Stop"

$GradleVersion = $env:GRADLE_VERSION
if ([string]::IsNullOrEmpty($GradleVersion)) {
    $GradleVersion = "latest"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$GradlePath = Join-Path $LibscriptHome "gradle\$GradleVersion\bin"
if (-not ($env:PATH -split ';' -contains $GradlePath)) {
    $env:PATH = "$GradlePath;" + $env:PATH
}