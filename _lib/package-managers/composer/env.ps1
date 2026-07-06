<#
.SYNOPSIS
Internal script for composer on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for composer.
#>

# Windows PowerShell env stub for composer

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:COMPOSER_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "composer") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
