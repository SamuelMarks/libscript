<#
.SYNOPSIS
Internal script for gitea on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for gitea.
#>

# Windows PowerShell env stub for gitea

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:GITEA_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "gitea") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
