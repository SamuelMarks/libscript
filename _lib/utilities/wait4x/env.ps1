# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for wait4x on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for wait4x.
#>

# Windows PowerShell env stub for wait4x

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:WAIT4X_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "wait4x") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
