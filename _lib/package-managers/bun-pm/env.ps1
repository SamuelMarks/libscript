<#
.SYNOPSIS
Internal script for bun-pm on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for bun-pm.
#>

# Windows PowerShell env stub for bun-pm

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:BUN_PM_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "bun-pm") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
