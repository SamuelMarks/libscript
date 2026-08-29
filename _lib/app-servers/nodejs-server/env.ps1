# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for nodejs-server on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for nodejs-server.
#>

# Windows PowerShell env stub for nodejs-server

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:NODEJS_SERVER_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "nodejs-server") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
