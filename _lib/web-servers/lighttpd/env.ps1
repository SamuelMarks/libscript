# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for lighttpd on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for lighttpd.
#>

# Windows PowerShell env stub for lighttpd

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:LIGHTTPD_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "lighttpd") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
