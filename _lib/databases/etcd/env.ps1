# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for etcd on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for etcd.
#>

# Windows PowerShell env stub for etcd

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:ETCD_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "etcd") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
