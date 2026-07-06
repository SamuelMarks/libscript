<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for go.
#>

$ErrorActionPreference = "Stop"

$GoVersion = $env:GO_VERSION
if ([string]::IsNullOrEmpty($GoVersion)) {
    $GoVersion = "latest"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$env:GOROOT = Join-Path $LibscriptHome "go\$GoVersion"
$GoPath = Join-Path $env:GOROOT "bin"
if (-not ($env:PATH -split ';' -contains $GoPath)) {
    $env:PATH = "$GoPath;" + $env:PATH
}
