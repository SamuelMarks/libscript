# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for rabbitmq on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for rabbitmq.
#>

# Windows PowerShell env stub for rabbitmq

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:RABBITMQ_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "rabbitmq") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
