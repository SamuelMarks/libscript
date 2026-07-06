<#
.SYNOPSIS
Internal script for jq on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for jq.
#>

# Windows PowerShell env stub for jq

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:JQ_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "jq") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
