<#
.SYNOPSIS
Internal script for nginx on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for nginx.
#>

# Windows PowerShell env stub for nginx

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:NGINX_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "nginx") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
