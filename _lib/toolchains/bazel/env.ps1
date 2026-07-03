<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for bazel.
#>

$BazelVersion = $env:BAZEL_VERSION
if ([string]::IsNullOrEmpty($BazelVersion)) {
    $BazelVersion = "latest"
}
if ($BazelVersion -eq "latest") {
    $BazelVersion = "v1.25.0"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "bazel\$BazelVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
