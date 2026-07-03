<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for sh.
#>

$ShVersion = $env:SH_VERSION
if ([string]::IsNullOrEmpty($ShVersion)) {
    $ShVersion = "0.5.12"
}
if ($ShVersion -eq "latest") {
    $ShVersion = "0.5.12"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "sh\$ShVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
