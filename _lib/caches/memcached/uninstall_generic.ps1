# ## Overview
# PowerShell script for uninstall_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Provides a generic, cross-platform uninstallation mechanism for the component 'memcached' stack.

.DESCRIPTION
Execute this script to perform generic removal steps for memcached.
#>

$ErrorActionPreference = "Stop"

$CompVersion = $env:MEMCACHED_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$TargetDir = Join-Path (Join-Path $LibscriptHome "memcached") $CompVersion
if (Test-Path $TargetDir) {
    Remove-Item -Recurse -Force $TargetDir
}
