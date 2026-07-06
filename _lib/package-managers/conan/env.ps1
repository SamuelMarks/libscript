<#
.SYNOPSIS
Internal script for conan on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for conan.
#>

# Windows PowerShell env stub for conan

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:CONAN_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "conan") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
