<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for php.
#>

$ErrorActionPreference = "Stop"

$PhpVersion = $env:PHP_VERSION
if ([string]::IsNullOrEmpty($PhpVersion)) {
    $PhpVersion = "latest"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$PhpPath = Join-Path $LibscriptHome "php\$PhpVersion\bin"
if (-not ($env:PATH -split ';' -contains $PhpPath)) {
    $env:PATH = "$PhpPath;" + $env:PATH
}