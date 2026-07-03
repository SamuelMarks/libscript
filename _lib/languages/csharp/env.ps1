<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for csharp.
#>

$CsharpVersion = $env:CSHARP_VERSION
if ([string]::IsNullOrEmpty($CsharpVersion)) {
    $CsharpVersion = "latest"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:DOTNET_ROOT = Join-Path $LibscriptHome "csharp" $CsharpVersion
$env:PATH = "$env:DOTNET_ROOT" + [IO.Path]::PathSeparator + $env:PATH
