# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for sqlite on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for sqlite.
#>

# Windows PowerShell env stub for sqlite

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:SQLITE_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "sqlite") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
