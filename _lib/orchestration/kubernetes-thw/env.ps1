# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for kubernetes-thw on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for kubernetes-thw.
#>

# Windows PowerShell env stub for kubernetes-thw

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:KUBERNETES_THW_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "kubernetes-thw") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
