<#
.SYNOPSIS
Internal script for 7zip on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for 7zip.
#>

# Windows PowerShell env stub for 7zip

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:SEVENZIP_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "7zip") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
