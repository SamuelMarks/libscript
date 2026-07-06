<#
.SYNOPSIS
Internal script for coursier on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for coursier.
#>

# Windows PowerShell env stub for coursier

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:COURSIER_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "coursier") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
