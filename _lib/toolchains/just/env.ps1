<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for just.
#>

$JustVersion = $env:JUST_VERSION
if ([string]::IsNullOrEmpty($JustVersion)) {
    $JustVersion = "latest"
}
if ($JustVersion -eq "latest") {
    $JustVersion = "1.39.0"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "just\$JustVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
