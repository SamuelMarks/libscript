<#
.SYNOPSIS
Internal script for brew on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for brew.
#>

# Windows PowerShell env stub for brew

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:BREW_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "brew") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
