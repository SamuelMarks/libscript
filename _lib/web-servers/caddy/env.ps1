<#
.SYNOPSIS
Internal script for caddy on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for caddy.
#>

# Windows PowerShell env stub for caddy

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:CADDY_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "caddy") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
