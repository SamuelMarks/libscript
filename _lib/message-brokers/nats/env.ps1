<#
.SYNOPSIS
Internal script for nats on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for nats.
#>

# Windows PowerShell env stub for nats

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:NATS_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "nats") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
