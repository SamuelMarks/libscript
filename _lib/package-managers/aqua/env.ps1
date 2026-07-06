<#
.SYNOPSIS
Internal script for aqua on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for aqua.
#>

# Windows PowerShell env stub for aqua

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:AQUA_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "aqua") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
