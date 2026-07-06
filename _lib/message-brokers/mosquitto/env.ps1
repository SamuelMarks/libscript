<#
.SYNOPSIS
Internal script for mosquitto on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for mosquitto.
#>

# Windows PowerShell env stub for mosquitto

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:MOSQUITTO_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "mosquitto") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
