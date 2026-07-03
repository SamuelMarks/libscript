<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for maven.
#>

$MavenVersion = $env:MAVEN_VERSION
if ([string]::IsNullOrEmpty($MavenVersion)) {
    $MavenVersion = "latest"
}
if ($MavenVersion -eq "latest") {
    $MavenVersion = "3.9.6"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "maven\$MavenVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
