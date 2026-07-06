<#
.SYNOPSIS
Internal script for docker on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for docker.
#>

# Windows PowerShell env stub for docker

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:DOCKER_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "docker") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
