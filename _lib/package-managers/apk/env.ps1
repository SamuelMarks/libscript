<#
.SYNOPSIS
Internal script for apk on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for apk.
#>

# Windows PowerShell env stub for apk

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:APK_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "apk") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
