<#
.SYNOPSIS
Internal script for deno-pm on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for deno-pm.
#>

# Windows PowerShell env stub for deno-pm

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:DENO_PM_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "deno-pm") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
