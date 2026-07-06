<#
.SYNOPSIS
Internal script for powershell on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for powershell.
#>

# Windows PowerShell env stub for powershell

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:POWERSHELL_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "powershell") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
