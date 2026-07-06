<#
.SYNOPSIS
Internal script for cargo-binstall on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for cargo-binstall.
#>

# Windows PowerShell env stub for cargo-binstall

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:CARGO_BINSTALL_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "cargo-binstall") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
