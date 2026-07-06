<#
.SYNOPSIS
Internal script for kafka on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for kafka.
#>

# Windows PowerShell env stub for kafka

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:KAFKA_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "kafka") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
