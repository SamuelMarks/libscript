<#
.SYNOPSIS
Internal script for choco on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for choco.
#>

# Windows PowerShell env stub for choco

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:CHOCO_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "choco") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
