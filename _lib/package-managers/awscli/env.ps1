<#
.SYNOPSIS
Internal script for awscli on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for awscli.
#>

# Windows PowerShell env stub for awscli

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:AWSCLI_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "awscli") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
