<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for coursier.
#>

$CoursierVersion = $env:COURSIER_VERSION
if ([string]::IsNullOrEmpty($CoursierVersion)) {
    $CoursierVersion = "latest"
}
if ($CoursierVersion -eq "latest") {
    $CoursierVersion = "2.1.24"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "coursier\$CoursierVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
