<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for kotlin.
#>

$KotlinVersion = $env:KOTLIN_VERSION
if ([string]::IsNullOrEmpty($KotlinVersion)) {
    $KotlinVersion = "1.9.20"
}
if ($KotlinVersion -eq "latest") {
    $KotlinVersion = "1.9.20"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "kotlin\$KotlinVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
