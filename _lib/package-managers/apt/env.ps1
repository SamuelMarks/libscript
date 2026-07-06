<#
.SYNOPSIS
Internal script for apt on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for apt.
#>

# Windows PowerShell env stub for apt

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:APT_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "apt") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
