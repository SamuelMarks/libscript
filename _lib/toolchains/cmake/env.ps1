<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for cmake.
#>

$CmakeVersion = $env:CMAKE_VERSION
if ([string]::IsNullOrEmpty($CmakeVersion)) {
    $CmakeVersion = "latest"
}
if ($CmakeVersion -eq "latest") {
    $CmakeVersion = "3.31.2"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "cmake\$CmakeVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
