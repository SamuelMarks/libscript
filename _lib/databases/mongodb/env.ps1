# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for mongodb on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for mongodb.
#>

# Windows PowerShell env stub for mongodb

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:MONGODB_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "mongodb") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
