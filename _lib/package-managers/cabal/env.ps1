<#
.SYNOPSIS
Internal script for cabal on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for cabal.
#>

# Windows PowerShell env stub for cabal

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:CABAL_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "cabal") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
